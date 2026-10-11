import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';

//import 'package:firebase_core/firebase_core.dart';



import 'services/user_access_service.dart';



class StaffManagementScreen extends StatefulWidget {

  const StaffManagementScreen({super.key});



  @override

  State<StaffManagementScreen> createState() =>

      _StaffManagementScreenState();

}



class _StaffManagementScreenState

    extends State<StaffManagementScreen> {

  final FirebaseFirestore _firestore =

      FirebaseFirestore.instance;



  final UserAccessService _accessService =

      UserAccessService.instance;



  bool _loading = true;

  bool _saving = false;



  String? _ownerId;



  List<_PropertyOption> _properties = [];

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _staff = [];



  @override

  void initState() {

    super.initState();

    _loadData();

  }



  Future<void> _loadData() async {

    try {

      final currentUser =

          FirebaseAuth.instance.currentUser;



      if (currentUser == null) {

        throw Exception('User is not logged in.');

      }



      final isOwner =

          await _accessService.isOwner();



      if (!isOwner) {

        throw Exception(

          'Only the main owner can manage staff.',

        );

      }



      final ownerId =

          await _accessService.ownerId();



      if (ownerId == null ||

          ownerId.trim().isEmpty) {

        throw Exception(

          'Owner ID could not be found.',

        );

      }



      _ownerId = ownerId;



      final propertiesSnapshot =

          await _firestore

              .collection('owners')

              .doc(ownerId)

              .collection('properties')

              .get();



      final properties =

          propertiesSnapshot.docs.map((doc) {

        final data = doc.data();



        return _PropertyOption(

          id: doc.id,

          name: _propertyName(

            data,

            doc.id,

          ),

          location: _propertyLocation(data),

        );

      }).toList();



      final staffSnapshot =

          await _firestore

              .collection('users')

              .where(

                'ownerId',

                isEqualTo: ownerId,

              )

              .get();



      final staff = staffSnapshot.docs

          .where((doc) {

        final data = doc.data();



        final role =

            (data['role'] ?? '')

                .toString()

                .trim()

                .toLowerCase();



        return role != 'owner';

      }).toList();



      staff.sort((a, b) {

        final aName =

            (a.data()['name'] ?? '')

                .toString()

                .toLowerCase();



        final bName =

            (b.data()['name'] ?? '')

                .toString()

                .toLowerCase();



        return aName.compareTo(bName);

      });



      if (!mounted) return;



      setState(() {

        _properties = properties;

        _staff = staff;

        _loading = false;

      });

    } catch (e) {

      if (!mounted) return;



      setState(() {

        _loading = false;

      });



      _showMessage(

        e.toString().replaceFirst(

          'Exception: ',

          '',

        ),

        isError: true,

      );

    }

  }



  static String _propertyName(

    Map<String, dynamic> data,

    String fallback,

  ) {

    final possibleNames = [

      data['name'],

      data['property_name'],

      data['propertyName'],

      data['building_name'],

      data['buildingName'],

      data['pg_name'],

      data['pgName'],

      data['title'],

    ];



    for (final value in possibleNames) {

      final text =

          value?.toString().trim() ?? '';



      if (text.isNotEmpty) {

        return text;

      }

    }



    return fallback;

  }



  static String _propertyLocation(

    Map<String, dynamic> data,

  ) {

    final possibleValues = [

      data['location'],

      data['address'],

      data['city'],

      data['area'],

    ];



    for (final value in possibleValues) {

      final text =

          value?.toString().trim() ?? '';



      if (text.isNotEmpty) {

        return text;

      }

    }



    return '';

  }



  Future<void> _showStaffEditor({

    DocumentSnapshot<Map<String, dynamic>>?

        staffDocument,

  }) async {

    final isEdit =

        staffDocument != null;



    final existingData =

        staffDocument?.data() ?? {};



    final nameController =

        TextEditingController(

      text:

          (existingData['name'] ?? '')

              .toString(),

    );



    final mobileController =

        TextEditingController(

      text:

          (existingData['mobile'] ?? '')

              .toString(),

    );



    final emailController =

        TextEditingController(

      text:

          (existingData['email'] ?? '')

              .toString(),

    );



    String selectedRole =

        (existingData['role'] ?? 'manager')

            .toString()

            .trim()

            .toLowerCase();



    const availableRoles = [

      'manager',

      'warden',

      'accountant',

      'staff',

    ];



    if (!availableRoles.contains(

      selectedRole,

    )) {

      selectedRole = 'manager';

    }



    final assignedRaw =

        existingData['assignedPropertyIds'];



    final selectedPropertyIds =

        <String>{

      if (assignedRaw is List)

        ...assignedRaw.map(

          (value) =>

              value.toString(),

        ),

    };



    bool isActive =

        ((existingData['status'] ??

                    'active')

                .toString()

                .trim()

                .toLowerCase() ==

            'active');



    final permissions =

        _loadPermissions(

      existingData['permissions'],

      selectedRole,

    );



    await showDialog<void>(

      context: context,

      barrierDismissible: false,

      builder: (dialogContext) {

        return StatefulBuilder(

          builder:

              (context, setDialogState) {

            return AlertDialog(

              title: Text(

                isEdit

                    ? 'Edit Staff'

                    : 'Add Staff',

              ),

              content: SizedBox(

                width: 520,

                child: SingleChildScrollView(

                  child: Column(

                    mainAxisSize:

                        MainAxisSize.min,

                    children: [

                      TextField(

                        controller:

                            nameController,

                        textInputAction:

                            TextInputAction.next,

                        decoration:

                            const InputDecoration(

                          labelText: 'Name *',

                          prefixIcon:

                              Icon(

                            Icons.person_outline,

                          ),

                          border:

                              OutlineInputBorder(),

                        ),

                      ),



                      const SizedBox(

                        height: 12,

                      ),



                      TextField(

                        controller:

                            mobileController,

                        keyboardType:

                            TextInputType.phone,

                        textInputAction:

                            TextInputAction.next,

                        decoration:

                            const InputDecoration(

                          labelText: 'Mobile',

                          prefixIcon:

                              Icon(

                            Icons.phone_outlined,

                          ),

                          border:

                              OutlineInputBorder(),

                        ),

                      ),



                      const SizedBox(

                        height: 12,

                      ),



                      TextField(

                        controller:

                            emailController,

                        keyboardType:

                            TextInputType.emailAddress,

                        readOnly: isEdit,

                        decoration:

                            InputDecoration(

                          labelText:

                              isEdit

                                  ? 'Login Email'

                                  : 'Login Email *',

                          helperText:

                              isEdit

                                  ? 'Login email cannot be changed here.'

                                  : 'A password setup email will be sent.',

                          prefixIcon:

                              const Icon(

                            Icons.email_outlined,

                          ),

                          border:

                              const OutlineInputBorder(),

                        ),

                      ),



                      const SizedBox(

                        height: 12,

                      ),



                      DropdownButtonFormField<

                          String>(

                        initialValue:

                            selectedRole,

                        decoration:

                            const InputDecoration(

                          labelText:

                              'Role',

                          prefixIcon:

                              Icon(

                            Icons.badge_outlined,

                          ),

                          border:

                              OutlineInputBorder(),

                        ),

                        items:

                            availableRoles

                                .map(

                          (role) {

                            return DropdownMenuItem<

                                String>(

                              value: role,

                              child: Text(

                                _roleLabel(

                                  role,

                                ),

                              ),

                            );

                          },

                        ).toList(),

                        onChanged:

                            (value) {

                          if (value ==

                              null) {

                            return;

                          }



                          setDialogState(() {

                            selectedRole =

                                value;



                            final defaults =

                                _defaultPermissions(

                              value,

                            );



                            for (final key

                                in defaults.keys) {

                              permissions[key] =

                                  defaults[key]!;

                            }

                          });

                        },

                      ),



                      const SizedBox(

                        height: 18,

                      ),



                      Align(

                        alignment:

                            Alignment.centerLeft,

                        child: Text(

                          'Assign PG(s)',

                          style:

                              Theme.of(

                                context,

                              )

                                  .textTheme

                                  .titleMedium

                                  ?.copyWith(

                                    fontWeight:

                                        FontWeight.w700,

                                  ),

                        ),

                      ),



                      const SizedBox(

                        height: 8,

                      ),



                      if (_properties.isEmpty)

                        Container(

                          width:

                              double.infinity,

                          padding:

                              const EdgeInsets.all(

                            12,

                          ),

                          decoration:

                              BoxDecoration(

                            color: Colors

                                .orange

                                .withValues(

                              alpha: 0.08,

                            ),

                            borderRadius:

                                BorderRadius

                                    .circular(

                              12,

                            ),

                          ),

                          child:

                              const Text(

                            'No PGs found. Please create a PG first.',

                          ),

                        )

                      else

                        ..._properties.map(

                          (property) {

                            final selected =

                                selectedPropertyIds

                                    .contains(

                              property.id,

                            );



                            return CheckboxListTile(

                              contentPadding:

                                  EdgeInsets.zero,

                              value: selected,

                              title: Text(

                                property.name,

                              ),

                              subtitle:

                                  property

                                      .location

                                      .isNotEmpty

                                  ? Text(

                                      property

                                          .location,

                                    )

                                  : null,

                              secondary:

                                  const Icon(

                                Icons

                                    .apartment_rounded,

                              ),

                              onChanged:

                                  (value) {

                                setDialogState(() {

                                  if (value ==

                                      true) {

                                    selectedPropertyIds

                                        .add(

                                      property.id,

                                    );

                                  } else {

                                    selectedPropertyIds

                                        .remove(

                                      property.id,

                                    );

                                  }

                                });

                              },

                            );

                          },

                        ),



                      const SizedBox(

                        height: 18,

                      ),



                      Align(

                        alignment:

                            Alignment.centerLeft,

                        child: Text(

                          'Permissions',

                          style:

                              Theme.of(

                                context,

                              )

                                  .textTheme

                                  .titleMedium

                                  ?.copyWith(

                                    fontWeight:

                                        FontWeight.w700,

                                  ),

                        ),

                      ),



                      const SizedBox(

                        height: 8,

                      ),



                      _permissionCheckbox(

                        context,

                        setDialogState,

                        permissions,

                        'dashboard',

                        'Dashboard',

                      ),



                      _permissionCheckbox(

                        context,

                        setDialogState,

                        permissions,

                        'rooms',

                        'Rooms & Beds',

                      ),



                      _permissionCheckbox(

                        context,

                        setDialogState,

                        permissions,

                        'tenants',

                        'Tenants',

                      ),



                      _permissionCheckbox(

                        context,

                        setDialogState,

                        permissions,

                        'payments',

                        'Payments',

                      ),



                      _permissionCheckbox(

                        context,

                        setDialogState,

                        permissions,

                        'expenses',

                        'Expenses',

                      ),



                      _permissionCheckbox(

                        context,

                        setDialogState,

                        permissions,

                        'bills',

                        'Bills',

                      ),



                      _permissionCheckbox(

                        context,

                        setDialogState,

                        permissions,

                        'reports',

                        'Reports',

                      ),



                      const SizedBox(

                        height: 8,

                      ),



                      SwitchListTile(

                        contentPadding:

                            EdgeInsets.zero,

                        title:

                            const Text(

                          'Staff Active',

                        ),

                        subtitle:

                            Text(

                          isActive

                              ? 'Staff can access assigned PGs.'

                              : 'Staff access is disabled.',

                        ),

                        value: isActive,

                        onChanged:

                            (value) {

                          setDialogState(() {

                            isActive =

                                value;

                          });

                        },

                      ),

                    ],

                  ),

                ),

              ),

              actions: [

                TextButton(

                  onPressed: _saving

                      ? null

                      : () {

                          Navigator.pop(

                            dialogContext,

                          );

                        },

                  child:

                      const Text('Cancel'),

                ),

                FilledButton.icon(

                  onPressed: _saving

                      ? null

                      : () async {

                          await _saveStaff(

                            dialogContext:

                                dialogContext,

                            staffDocument:

                                staffDocument,

                            name:

                                nameController

                                    .text,

                            mobile:

                                mobileController

                                    .text,

                            email:

                                emailController

                                    .text,

                            role:

                                selectedRole,

                            selectedPropertyIds:

                                selectedPropertyIds

                                    .toList(),

                            permissions:

                                permissions,

                            isActive:

                                isActive,

                          );

                        },

                  icon: _saving

                      ? const SizedBox(

                          width: 18,

                          height: 18,

                          child:

                              CircularProgressIndicator(

                            strokeWidth: 2,

                          ),

                        )

                      : const Icon(

                          Icons.save_rounded,

                        ),

                  label: Text(

                    isEdit

                        ? 'Save Changes'

                        : 'Create Staff',

                  ),

                ),

              ],

            );

          },

        );

      },

    );

        await Future<void>.delayed(

      const Duration(milliseconds: 300),

    );

    nameController.dispose();

    mobileController.dispose();

    emailController.dispose();

  }



  Map<String, bool> _loadPermissions(

    dynamic raw,

    String role,

  ) {

    final defaults =

        _defaultPermissions(role);



    if (raw is Map) {

      for (final entry in raw.entries) {

        defaults[

                entry.key.toString()] =

            entry.value == true;

      }

    }



    return defaults;

  }



  Map<String, bool> _defaultPermissions(

    String role,

  ) {

    switch (role) {

      case 'manager':

        return {

          'dashboard': true,

          'rooms': true,

          'tenants': true,

          'payments': true,

          'expenses': true,

          'bills': true,

          'reports': true,

        };



      case 'warden':

        return {

          'dashboard': true,

          'rooms': true,

          'tenants': true,

          'payments': false,

          'expenses': false,

          'bills': false,

          'reports': false,

        };



      case 'accountant':

        return {

          'dashboard': true,

          'rooms': false,

          'tenants': false,

          'payments': true,

          'expenses': true,

          'bills': true,

          'reports': true,

        };



      case 'staff':

      default:

        return {

          'dashboard': true,

          'rooms': true,

          'tenants': true,

          'payments': false,

          'expenses': false,

          'bills': false,

          'reports': false,

        };

    }

  }



  Widget _permissionCheckbox(

    BuildContext context,

    StateSetter setDialogState,

    Map<String, bool> permissions,

    String key,

    String title,

  ) {

    return CheckboxListTile(

      contentPadding:

          EdgeInsets.zero,

      value: permissions[key] ?? false,

      title: Text(title),

      onChanged: (value) {

        setDialogState(() {

          permissions[key] =

              value ?? false;

        });

      },

    );

  }



  Future<void> _saveStaff({

    required BuildContext dialogContext,

    required DocumentSnapshot<

            Map<String, dynamic>>?

        staffDocument,

    required String name,

    required String mobile,

    required String email,

    required String role,

    required List<String>

        selectedPropertyIds,

    required Map<String, bool>

        permissions,

    required bool isActive,

  }) async {

    final cleanName =

        name.trim();



    final cleanMobile =

        mobile.trim();



    final cleanEmail =

        email.trim().toLowerCase();



    if (cleanName.isEmpty) {

      _showMessage(

        'Please enter staff name.',

        isError: true,

      );

      return;

    }



    if (selectedPropertyIds.isEmpty &&

        isActive) {

      _showMessage(

        'Please assign at least one PG to active staff.',

        isError: true,

      );

      return;

    }



    final ownerId = _ownerId;



    if (ownerId == null ||

        ownerId.isEmpty) {

      _showMessage(

        'Owner ID not found.',

        isError: true,

      );

      return;

    }



    setState(() {

      _saving = true;

    });



    try {

      if (staffDocument != null) {

        await _firestore

            .collection('users')

            .doc(staffDocument.id)

            .update({

          'name': cleanName,

          'mobile': cleanMobile,

          'role': role,

          'ownerId': ownerId,

          'assignedPropertyIds':

              selectedPropertyIds,

          'permissions':

              permissions,

          'status':

              isActive

                  ? 'active'

                  : 'inactive',

          'updatedAt':

              FieldValue.serverTimestamp(),

        });



        if (mounted) {

          Navigator.pop(

            dialogContext,

          );

        }



        _showMessage(

          'Staff details updated successfully.',

        );



        await _loadData();

        return;

      }



      if (cleanEmail.isEmpty) {

        throw Exception(

          'Email is required when creating a new staff login.',

        );

      }



      /*

       * Create the Firebase Auth user using

       * a secondary Firebase app so the

       * current Owner login is not replaced.

       */

      final primaryApp =

          Firebase.app();



      final secondaryApp =

          await Firebase.initializeApp(

        name:

            'staffCreator_${DateTime.now().microsecondsSinceEpoch}',

        options:

            primaryApp.options,

      );



      final secondaryAuth =

          FirebaseAuth.instanceFor(

        app: secondaryApp,

      );



      UserCredential?

          credential;



      try {

        final temporaryPassword =

            _generateTemporaryPassword();



        credential =

            await secondaryAuth

                .createUserWithEmailAndPassword(

          email: cleanEmail,

          password:

              temporaryPassword,

        );



        final newUser =

            credential.user;



        if (newUser == null) {

          throw Exception(

            'Staff Firebase account could not be created.',

          );

        }



        await secondaryAuth

            .sendPasswordResetEmail(

          email: cleanEmail,

        );



        await _firestore

            .collection('users')

            .doc(newUser.uid)

            .set({

          'uid': newUser.uid,

          'name': cleanName,

          'mobile': cleanMobile,

          'email': cleanEmail,

          'role': role,

          'ownerId': ownerId,

          'assignedPropertyIds':

              selectedPropertyIds,

          'permissions':

              permissions,

          'status':

              isActive

                  ? 'active'

                  : 'inactive',

          'createdAt':

              FieldValue.serverTimestamp(),

          'updatedAt':

              FieldValue.serverTimestamp(),

        });

      } finally {

        await secondaryAuth.signOut();



        try {

          await secondaryApp.delete();

        } catch (_) {}

      }



      if (mounted) {

        Navigator.pop(

          dialogContext,

        );

      }



      _showMessage(

        'Staff created successfully. Password setup email sent to $cleanEmail.',

      );



      await _loadData();

    } on FirebaseAuthException catch (e) {

      String message;



      switch (e.code) {

        case 'email-already-in-use':

          message =

              'This email is already registered in Firebase.';

          break;



        case 'invalid-email':

          message =

              'Please enter a valid email address.';

          break;



        case 'operation-not-allowed':

          message =

              'Email/Password authentication is not enabled in Firebase Authentication.';

          break;



        case 'weak-password':

          message =

              'Unable to create the staff login because of password policy.';

          break;



        default:

          message =

              e.message ??

                  'Firebase Authentication error.';

      }



      _showMessage(

        message,

        isError: true,

      );

    } catch (e) {

      _showMessage(

        e.toString().replaceFirst(

          'Exception: ',

          '',

        ),

        isError: true,

      );

    } finally {

      if (mounted) {

        setState(() {

          _saving = false;

        });

      }

    }

  }



  String _generateTemporaryPassword() {

    final timestamp =

        DateTime.now()

            .microsecondsSinceEpoch;



    return 'Sm${timestamp}#A9';

  }



  Future<void> _toggleStaffStatus(

    DocumentSnapshot<

            Map<String, dynamic>>

        staffDocument,

  ) async {

    final data =

        staffDocument.data();



    final currentStatus =

        (data?['status'] ??

                'active')

            .toString()

            .trim()

            .toLowerCase();



    final newStatus =

        currentStatus == 'active'

            ? 'inactive'

            : 'active';



    try {

      await _firestore

          .collection('users')

          .doc(staffDocument.id)

          .update({

        'status': newStatus,

        'updatedAt':

            FieldValue.serverTimestamp(),

      });



      _showMessage(

        newStatus == 'active'

            ? 'Staff access enabled.'

            : 'Staff access disabled.',

      );



      await _loadData();

    } catch (e) {

      _showMessage(

        e.toString().replaceFirst(

          'Exception: ',

          '',

        ),

        isError: true,

      );

    }

  }




  Future<void> _permanentlyDeleteStaff(
    QueryDocumentSnapshot<Map<String, dynamic>> staffDocument,
  ) async {
    final data = staffDocument.data();

    final name = (data['name'] ?? 'Staff').toString().trim();
    final email = (data['email'] ?? '').toString().trim();
    final staffUid = staffDocument.id;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 40,
        ),
        title: const Text('Permanently Delete Staff?'),
        content: Text(
          'Staff: $name\n'
          '${email.isNotEmpty ? 'Email: $email\n\n' : '\n'}'
          'This action cannot be undone. The staff login account '
          'and staff profile will be deleted permanently.\n\n'
          'PG records, tenants, rooms, payments and transactions '
          'will not be deleted by this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('permanentlyDeleteStaff');

      final result = await callable.call<Map<String, dynamic>>({
        'staffUid': staffUid,
      });

      if (result.data['success'] != true) {
        throw Exception('The server did not confirm deletion.');
      }

      if (!mounted) return;

      _showMessage('Staff account permanently deleted.');
      await _loadData();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'unauthenticated':
          message = 'Please sign in again and retry.';
          break;
        case 'permission-denied':
          message =
              'You are not authorized to delete this staff account.';
          break;
        case 'not-found':
          message = 'Staff profile was not found.';
          break;
        case 'invalid-argument':
          message = 'Invalid staff account details.';
          break;
        default:
          message = e.message ??
              'Unable to delete the staff account. Please check and retry.';
      }

      _showMessage(message, isError: true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to complete staff deletion. Please verify the account '
        'before retrying.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _roleLabel(String role) {

    switch (role) {

      case 'manager':

        return 'Manager';

      case 'warden':

        return 'Warden';

      case 'accountant':

        return 'Accountant';

      case 'staff':

        return 'Staff';

      default:

        return role;

    }

  }



  void _showMessage(

    String message, {

    bool isError = false,

  }) {

    if (!mounted) return;



    ScaffoldMessenger.of(context)

      ..hideCurrentSnackBar()

      ..showSnackBar(

        SnackBar(

          content: Text(message),

          backgroundColor:

              isError

                  ? Colors.red.shade700

                  : null,

        ),

      );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title:

            const Text('Staff Management'),

        centerTitle: false,

      ),

      floatingActionButton:

          FloatingActionButton.extended(

        onPressed:

            _loading || _saving

                ? null

                : () {

                    _showStaffEditor();

                  },

        icon: const Icon(

          Icons.person_add_alt_1_rounded,

        ),

        label:

            const Text('Add Staff'),

      ),

      body: _loading

          ? const Center(

              child:

                  CircularProgressIndicator(),

            )

          : RefreshIndicator(

              onRefresh: _loadData,

              child:

                  _staff.isEmpty

                      ? ListView(

                          physics:

                              const AlwaysScrollableScrollPhysics(),

                          padding:

                              const EdgeInsets.all(

                            24,

                          ),

                          children: [

                            const SizedBox(

                              height: 100,

                            ),

                            Icon(

                              Icons

                                  .group_outlined,

                              size: 72,

                              color: Colors

                                  .grey

                                  .shade400,

                            ),

                            const SizedBox(

                              height: 16,

                            ),

                            Text(

                              'No staff members yet',

                              textAlign:

                                  TextAlign.center,

                              style:

                                  Theme.of(

                                    context,

                                  )

                                      .textTheme

                                      .titleLarge

                                      ?.copyWith(

                                        fontWeight:

                                            FontWeight.w700,

                                      ),

                            ),

                            const SizedBox(

                              height: 8,

                            ),

                            Text(

                              'Tap Add Staff to create a staff account and assign PG access.',

                              textAlign:

                                  TextAlign.center,

                              style:

                                  TextStyle(

                                color: Colors

                                    .grey

                                    .shade600,

                              ),

                            ),

                          ],

                        )

                      : ListView.separated(

                          physics:

                              const AlwaysScrollableScrollPhysics(),

                          padding:

                              const EdgeInsets.fromLTRB(

                            16,

                            16,

                            16,

                            100,

                          ),

                          itemCount:

                              _staff.length,

                          separatorBuilder:

                              (_, __) =>

                                  const SizedBox(

                            height: 12,

                          ),

                          itemBuilder:

                              (context, index) {

                            final staff =

                                _staff[index];



                            return _staffCard(

                              staff,

                            );

                          },

                        ),

            ),

    );

  }



  Widget _staffCard(

    QueryDocumentSnapshot<

            Map<String, dynamic>>

        staff,

  ) {

    final data =

        staff.data();



    final name =

        (data['name'] ?? 'Staff')

            .toString()

            .trim();



    final email =

        (data['email'] ?? '')

            .toString()

            .trim();



    final mobile =

        (data['mobile'] ?? '')

            .toString()

            .trim();



    final role =

        (data['role'] ?? 'staff')

            .toString()

            .trim()

            .toLowerCase();



    final status =

        (data['status'] ?? 'active')

            .toString()

            .trim()

            .toLowerCase();



    final isActive =

        status == 'active';



    final assignedRaw =

        data['assignedPropertyIds'];



    final assignedIds =

        assignedRaw is List

            ? assignedRaw

                .map(

                  (value) =>

                      value.toString(),

                )

                .toList()

            : <String>[];



    final assignedNames =

        assignedIds.map((id) {

      final match =

          _properties.where(

        (property) =>

            property.id == id,

      );



      if (match.isEmpty) {

        return id;

      }



      return match.first.name;

    }).toList();



    return Card(

      elevation: 0,

      shape:

          RoundedRectangleBorder(

        borderRadius:

            BorderRadius.circular(18),

        side: BorderSide(

          color:

              Colors.grey.shade200,

        ),

      ),

      child: Padding(

        padding:

            const EdgeInsets.all(16),

        child: Column(

          children: [

            Row(

              children: [

                CircleAvatar(

                  radius: 25,

                  child: Text(

                    name.isNotEmpty

                        ? name[0]

                            .toUpperCase()

                        : 'S',

                    style:

                        const TextStyle(

                      fontWeight:

                          FontWeight.w700,

                    ),

                  ),

                ),



                const SizedBox(

                  width: 12,

                ),



                Expanded(

                  child: Column(

                    crossAxisAlignment:

                        CrossAxisAlignment

                            .start,

                    children: [

                      Text(

                        name.isEmpty

                            ? 'Staff'

                            : name,

                        style:

                            const TextStyle(

                          fontSize: 17,

                          fontWeight:

                              FontWeight.w700,

                        ),

                      ),

                      const SizedBox(

                        height: 4,

                      ),

                      Text(

                        _roleLabel(role),

                        style:

                            TextStyle(

                          color: Theme.of(

                            context,

                          )

                              .colorScheme

                              .primary,

                          fontWeight:

                              FontWeight.w600,

                        ),

                      ),

                    ],

                  ),

                ),



                PopupMenuButton<String>(

                  onSelected:

                      (value) async {

                    if (value ==

                        'edit') {

                      await _showStaffEditor(

                        staffDocument:

                            staff,

                      );

                    } else if (value ==

                        'toggle') {

                      await _toggleStaffStatus(

                        staff,

                      );

                    } else if (value == 'delete') {

                      await _permanentlyDeleteStaff(staff);

                    }

                  },

                  itemBuilder:

                      (context) => [

                    const PopupMenuItem<

                        String>(

                      value: 'edit',

                      child: ListTile(

                        contentPadding:

                            EdgeInsets.zero,

                        leading: Icon(

                          Icons

                              .edit_outlined,

                        ),

                        title:

                            Text('Edit'),

                      ),

                    ),

                    PopupMenuItem<String>(

                      value: 'toggle',

                      child: ListTile(

                        contentPadding:

                            EdgeInsets.zero,

                        leading: Icon(

                          isActive

                              ? Icons

                                  .block_outlined

                              : Icons

                                  .check_circle_outline,

                        ),

                        title: Text(

                          isActive

                              ? 'Disable Access'

                              : 'Enable Access',

                        ),

                      ),

                    ),

                    const PopupMenuItem<String>(

                      value: 'delete',

                      child: ListTile(

                        contentPadding: EdgeInsets.zero,

                        leading: Icon(

                          Icons.delete_forever_outlined,

                          color: Colors.red,

                        ),

                        title: Text(

                          'Permanently Delete',

                          style: TextStyle(color: Colors.red),

                        ),

                      ),

                    ),

                  ],

                ),

              ],

            ),



            const SizedBox(

              height: 12,

            ),



            if (email.isNotEmpty)

              _infoRow(

                Icons.email_outlined,

                email,

              ),



            if (mobile.isNotEmpty)

              _infoRow(

                Icons.phone_outlined,

                mobile,

              ),



            _infoRow(

              Icons.apartment_rounded,

              assignedNames.isEmpty

                  ? 'No PG assigned'

                  : assignedNames.join(

                      ', ',

                    ),

            ),



            const SizedBox(

              height: 10,

            ),



            Row(

              children: [

                Container(

                  padding:

                      const EdgeInsets.symmetric(

                    horizontal: 10,

                    vertical: 6,

                  ),

                  decoration:

                      BoxDecoration(

                    color: isActive

                        ? Colors.green

                            .withValues(

                            alpha: 0.10,

                          )

                        : Colors.red

                            .withValues(

                            alpha: 0.10,

                          ),

                    borderRadius:

                        BorderRadius.circular(

                      20,

                    ),

                  ),

                  child: Text(

                    isActive

                        ? 'ACTIVE'

                        : 'INACTIVE',

                    style:

                        TextStyle(

                      fontSize: 11,

                      fontWeight:

                          FontWeight.w800,

                      color: isActive

                          ? Colors.green

                              .shade700

                          : Colors.red

                              .shade700,

                    ),

                  ),

                ),



                const Spacer(),



                Text(

                  '${assignedIds.length} PG${assignedIds.length == 1 ? '' : 's'}',

                  style:

                      TextStyle(

                    color: Colors

                        .grey

                        .shade600,

                    fontWeight:

                        FontWeight.w600,

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }



  Widget _infoRow(

    IconData icon,

    String text,

  ) {

    return Padding(

      padding:

          const EdgeInsets.only(

        top: 6,

      ),

      child: Row(

        crossAxisAlignment:

            CrossAxisAlignment.start,

        children: [

          Icon(

            icon,

            size: 18,

            color: Colors

                .grey

                .shade600,

          ),

          const SizedBox(

            width: 8,

          ),

          Expanded(

            child: Text(

              text,

              style:

                  TextStyle(

                color: Colors

                    .grey

                    .shade700,

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _PropertyOption {

  final String id;

  final String name;

  final String location;



  const _PropertyOption({

    required this.id,

    required this.name,

    required this.location,

  });

}