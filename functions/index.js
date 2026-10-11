
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

setGlobalOptions({
  maxInstances: 5,
  region: "asia-south1",
});

const allowedStaffRoles = [
  "manager",
  "warden",
  "accountant",
  "staff",
];

exports.permanentlyDeleteStaff = onCall(async (request) => {
  // 1. The caller must be signed in.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Please sign in before deleting a staff account."
    );
  }

  const ownerUid = request.auth.uid;
  const staffUid = request.data?.staffUid;

  if (
    typeof staffUid !== "string" ||
    staffUid.trim().length === 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A valid staffUid is required."
    );
  }

  // Never allow the caller to delete their own account.
  if (staffUid === ownerUid) {
    throw new HttpsError(
      "permission-denied",
      "You cannot delete your own account using this function."
    );
  }

  const db = getFirestore();
  const ownerRef = db.collection("users").doc(ownerUid);
  const staffRef = db.collection("users").doc(staffUid);

  // 2. Verify that the caller is an active owner.
  const ownerSnap = await ownerRef.get();

  if (!ownerSnap.exists) {
    throw new HttpsError(
      "permission-denied",
      "Owner profile was not found."
    );
  }

  const owner = ownerSnap.data();

  if (
    owner.role !== "owner" ||
    owner.ownerId !== ownerUid ||
    owner.status !== "active"
  ) {
    throw new HttpsError(
      "permission-denied",
      "Only an active owner can permanently delete staff."
    );
  }

  // 3. Verify the target is staff belonging to this owner.
  const staffSnap = await staffRef.get();

  if (!staffSnap.exists) {
    throw new HttpsError(
      "not-found",
      "Staff profile was not found."
    );
  }

  const staff = staffSnap.data();

  if (
    !allowedStaffRoles.includes(staff.role) ||
    staff.ownerId !== ownerUid
  ) {
    throw new HttpsError(
      "permission-denied",
      "You can delete only staff accounts belonging to your business."
    );
  }

  // 4. Delete only the staff Authentication account and profile.
  // Do not delete properties, tenants, rooms, payments, or other records.
  try {
    await getAuth().deleteUser(staffUid);
  } catch (error) {
    // If the Auth user is already absent, allow profile cleanup.
    if (error.code !== "auth/user-not-found") {
      console.error("Staff Auth deletion failed:", error.code);
      throw new HttpsError(
        "internal",
        "Could not delete the staff Authentication account. No Firestore profile was deleted."
      );
    }
  }

  try {
    await staffRef.delete();
  } catch (error) {
    console.error("Staff profile deletion failed:", error);
    throw new HttpsError(
      "internal",
      "The Auth account was deleted, but the staff profile cleanup failed. Please contact support."
    );
  }

  return {
    success: true,
    deletedStaffUid: staffUid,
    message: "Staff account and profile deleted.",
  };
});
