import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'pg_manager_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() =>
      _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _loading = true;

  List<Map<String, dynamic>> _documents = [];

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // ============================================================
  // FIREBASE REFERENCES
  // ============================================================

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  String? get _ownerId =>
      _currentUser?.uid;

  String? get _propertyId =>
      PgManagerService.activePgId;

  CollectionReference<Map<String, dynamic>>?
      get _documentsCollection {
    final ownerId = _ownerId;
    final propertyId = _propertyId;

    if (ownerId == null ||
        ownerId.isEmpty ||
        propertyId == null ||
        propertyId.isEmpty) {
      return null;
    }

    return _firestore
        .collection('owners')
        .doc(ownerId)
        .collection('properties')
        .doc(propertyId)
        .collection('documents');
  }

  String _storagePath({
    required String fileName,
  }) {
    final ownerId = _ownerId!;
    final propertyId = _propertyId!;

    return 'owners/$ownerId/'
        'properties/$propertyId/'
        'documents/$fileName';
  }

  @override
  void initState() {
    super.initState();
    _initializeDocuments();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeDocuments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _documents = [];
          _loading = false;
        });

        _showMessage(
          'Please login to view documents.',
          isError: true,
        );

        return;
      }

      final propertyId =
          PgManagerService.activePgId;

      if (propertyId == null ||
          propertyId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _documents = [];
          _loading = false;
        });

        _showMessage(
          'Please select a PG first.',
          isError: true,
        );

        return;
      }

      await _loadDocuments();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load documents.',
        isError: true,
      );
    }
  }

  // ============================================================
  // LOAD DOCUMENTS
  // ============================================================

  Future<void> _loadDocuments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _documents = [];
          _loading = false;
        });

        return;
      }

      final propertyId =
          PgManagerService.activePgId;

      if (propertyId == null ||
          propertyId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _documents = [];
          _loading = false;
        });

        return;
      }

      final snapshot = await _firestore
          .collection('owners')
          .doc(user.uid)
          .collection('properties')
          .doc(propertyId)
          .collection('documents')
          .orderBy(
            'created_at',
            descending: true,
          )
          .get();

      final documents =
          snapshot.docs.map((doc) {
        final data = doc.data();

        return <String, dynamic>{
          'id': doc.id,
          ...data,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _documents = documents;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load documents.',
        isError: true,
      );
    }
  }

  // ============================================================
  // ADD DOCUMENT
  // ============================================================

  Future<void> _showAddDocument() async {
    final nameController = TextEditingController();

    String selectedType = 'Other';

    PlatformFile? selectedFile;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // TOP HANDLE
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD1D5DB),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // TITLE
                      const Text(
                        'Add Document',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // DOCUMENT NAME
                      // ==================================================

                      const Text(
                        'Document Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xFF374151),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller:
                            nameController,
                        textInputAction:
                            TextInputAction.done,
                        decoration:
                            InputDecoration(
                          hintText:
                              'Example: Rental Agreement',
                          prefixIcon:
                              const Icon(
                            Icons
                                .description_outlined,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  Color(0xFF2563EB),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // DOCUMENT TYPE
                      // ==================================================

                      const Text(
                        'Document Type',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xFF374151),
                        ),
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        initialValue:
                            selectedType,
                        decoration:
                            InputDecoration(
                          prefixIcon:
                              const Icon(
                            Icons
                                .category_outlined,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  Color(0xFF2563EB),
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value:
                                'Rental Agreement',
                            child: Text(
                              'Rental Agreement',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Owner ID Proof',
                            child: Text(
                              'Owner ID Proof',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Property Document',
                            child: Text(
                              'Property Document',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Tenant Document',
                            child: Text(
                              'Tenant Document',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child:
                                Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setSheetState(() {
                            selectedType =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // ATTACHMENT
                      // ==================================================

                      const Text(
                        'Attachment',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(0xFF374151),
                        ),
                      ),

                      const SizedBox(height: 8),

                      InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        onTap: () async {
                          try {
                            final picked =
                                await FilePicker
                                    .platform
                                    .pickFiles(
                              type:
                                  FileType.custom,
                              allowedExtensions: [
                                'pdf',
                                'jpg',
                                'jpeg',
                                'png',
                                'doc',
                                'docx',
                              ],
                            );

                            if (picked ==
                                    null ||
                                picked.files
                                    .isEmpty) {
                              return;
                            }

                            setSheetState(() {
                              selectedFile =
                                  picked.files.first;
                            });
                          } catch (e) {
                            if (!mounted) {
                              return;
                            }

                            _showMessage(
                              'Unable to select file.',
                              isError: true,
                            );
                          }
                        },
                        child: Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFF8FAFC,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            border: Border.all(
                              color:
                                  const Color(
                                0xFFE5E7EB,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFEFF6FF,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .attach_file_rounded,
                                  color:
                                      Color(
                                    0xFF2563EB,
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
                                      selectedFile ==
                                              null
                                          ? 'Choose File'
                                          : selectedFile!
                                              .name,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            14,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                        color:
                                            Color(
                                          0xFF111827,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      selectedFile ==
                                              null
                                          ? 'PDF, JPG, PNG, DOC, DOCX'
                                          : 'File selected',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            12,
                                        color:
                                            Color(
                                          0xFF64748B,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons
                                    .chevron_right_rounded,
                                color:
                                    Color(
                                  0xFF94A3B8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // SAVE BUTTON
                      // ==================================================

                      SizedBox(
                        width:
                            double.infinity,
                        height: 52,
                        child:
                            FilledButton.icon(
                          onPressed:
                              selectedFile ==
                                      null
                                  ? null
                                  : () async {
                                      final name =
                                          nameController
                                              .text
                                              .trim();

                                      if (name
                                          .isEmpty) {
                                        ScaffoldMessenger
                                                .of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text(
                                              'Please enter document name.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      Navigator.pop(
                                        context,
                                        true,
                                      );

                                      await _saveDocument(
                                        name: name,
                                        type:
                                            selectedType,
                                        file:
                                            selectedFile!,
                                      );
                                    },
                          icon:
                              const Icon(
                            Icons.save_rounded,
                          ),
                          label:
                              const Text(
                            'Save Document',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();

    if (result == true) {
      await _loadDocuments();
    }
  }

  // ============================================================
  // SAVE DOCUMENT
  // ============================================================

  Future<void> _saveDocument({
    required String name,
    required String type,
    required PlatformFile file,
  }) async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showMessage(
          'Please login to save documents.',
          isError: true,
        );
        return;
      }

      final propertyId =
          PgManagerService.activePgId;

      if (propertyId == null ||
          propertyId.isEmpty) {
        _showMessage(
          'Please select a PG first.',
          isError: true,
        );
        return;
      }

      if (file.path == null ||
          file.path!.isEmpty) {
        _showMessage(
          'Unable to access selected file.',
          isError: true,
        );
        return;
      }

      final sourceFile =
          File(file.path!);

      if (!await sourceFile.exists()) {
        _showMessage(
          'Selected file is no longer available.',
          isError: true,
        );
        return;
      }

      // ----------------------------------------------------------
      // FILE NAME
      // ----------------------------------------------------------

      final timestamp =
          DateTime.now()
              .millisecondsSinceEpoch;

      final originalFileName =
          file.name.trim().isEmpty
              ? 'document'
              : file.name.trim();

      final safeFileName =
          '${timestamp}_$originalFileName';

      // ----------------------------------------------------------
      // STORAGE PATH
      // ----------------------------------------------------------

      final storagePath =
          _storagePath(
        fileName: safeFileName,
      );

      final storageRef =
          _storage.ref().child(
                storagePath,
              );

      // ----------------------------------------------------------
      // CONTENT TYPE
      // ----------------------------------------------------------

      final extension =
          originalFileName
              .contains('.')
              ? originalFileName
                  .split('.')
                  .last
                  .toLowerCase()
              : '';

      String contentType;

      switch (extension) {
        case 'pdf':
          contentType =
              'application/pdf';
          break;

        case 'jpg':
        case 'jpeg':
          contentType =
              'image/jpeg';
          break;

        case 'png':
          contentType =
              'image/png';
          break;

        case 'doc':
          contentType =
              'application/msword';
          break;

        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;

        default:
          contentType =
              'application/octet-stream';
      }

      // ----------------------------------------------------------
      // UPLOAD TO FIREBASE STORAGE
      // ----------------------------------------------------------

      await storageRef.putFile(
        sourceFile,
        SettableMetadata(
          contentType: contentType,
          cacheControl:
              'private,max-age=3600',
        ),
      );

      // ----------------------------------------------------------
      // DOWNLOAD URL
      // ----------------------------------------------------------

      final downloadUrl =
          await storageRef.getDownloadURL();

      // ----------------------------------------------------------
      // FIRESTORE METADATA
      // ----------------------------------------------------------

      final createdAt =
          DateTime.now();

      final documentsCollection =
          _firestore
              .collection('owners')
              .doc(user.uid)
              .collection('properties')
              .doc(propertyId)
              .collection('documents');

      await documentsCollection.add({
        'name': name,
        'type': type,
        'file_name':
            originalFileName,
        'file_path':
            storagePath,
        'storage_path':
            storagePath,
        'download_url':
            downloadUrl,
        'content_type':
            contentType,
        'file_extension':
            extension,
        'created_at':
            Timestamp.fromDate(
          createdAt,
        ),
        'created_by':
            user.uid,
      });

      await _loadDocuments();

      if (!mounted) return;

      _showMessage(
        'Document saved successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to save document.',
        isError: true,
      );
    }
  }

  // ============================================================
  // OPEN DOCUMENT
  // ============================================================

  Future<void> _openDocument(
    Map<String, dynamic> document,
  ) async {
    try {
      final storagePath =
          document['storage_path']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? document['storage_path']
              .toString()
          : document['file_path']
              ?.toString()
              .trim();

      if (storagePath == null ||
          storagePath.isEmpty) {
        _showMessage(
          'File path not available.',
          isError: true,
        );
        return;
      }

      final storageRef =
          _storage.ref().child(
                storagePath,
              );

      // ----------------------------------------------------------
      // DOWNLOAD FILE FROM FIREBASE STORAGE
      // ----------------------------------------------------------

      final bytes =
          await storageRef.getData(
        50 * 1024 * 1024,
      );

      if (bytes == null ||
          bytes.isEmpty) {
        _showMessage(
          'File is no longer available.',
          isError: true,
        );
        return;
      }

      // ----------------------------------------------------------
      // CREATE TEMP FILE
      // ----------------------------------------------------------

      final tempDirectory =
          await getTemporaryDirectory();

      final fileName =
          document['file_name']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? document['file_name']
              .toString()
          : 'document';

      final safeTempName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final localFile =
          File(
        '${tempDirectory.path}/$safeTempName',
      );

      await localFile.writeAsBytes(
        bytes,
        flush: true,
      );

      // ----------------------------------------------------------
      // OPEN FILE
      // ----------------------------------------------------------

      await OpenFilex.open(
        localFile.path,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to open this file.',
        isError: true,
      );
    }
  }

  // ============================================================
  // DELETE DOCUMENT
  // ============================================================

  Future<void> _deleteDocument(
    Map<String, dynamic> document,
  ) async {
    final documentId =
        document['id']?.toString();

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          title: const Text(
            'Delete Document?',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${document['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFDC2626,
                ),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showMessage(
          'Please login first.',
          isError: true,
        );
        return;
      }

      final propertyId =
          PgManagerService.activePgId;

      if (propertyId == null ||
          propertyId.isEmpty) {
        _showMessage(
          'Please select a PG first.',
          isError: true,
        );
        return;
      }

      if (documentId == null ||
          documentId.isEmpty) {
        _showMessage(
          'Document ID not available.',
          isError: true,
        );
        return;
      }

      // ----------------------------------------------------------
      // DELETE FIREBASE STORAGE FILE
      // ----------------------------------------------------------

      final storagePath =
          document['storage_path']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? document['storage_path']
              .toString()
          : document['file_path']
              ?.toString()
              .trim();

      if (storagePath != null &&
          storagePath.isNotEmpty) {
        try {
          await _storage
              .ref()
              .child(storagePath)
              .delete();
        } catch (e) {
          // If the file is already missing from Storage,
          // continue with Firestore deletion.
        }
      }

      // ----------------------------------------------------------
      // DELETE FIRESTORE DOCUMENT
      // ----------------------------------------------------------

      await _firestore
          .collection('owners')
          .doc(user.uid)
          .collection('properties')
          .doc(propertyId)
          .collection('documents')
          .doc(documentId)
          .delete();

      await _loadDocuments();

      if (!mounted) return;

      _showMessage(
        'Document deleted.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to delete document.',
        isError: true,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              isError
                  ? const Color(
                      0xFFDC2626,
                    )
                  : null,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.white,
        foregroundColor:
            const Color(0xFF111827),

        title: const Text(
          'Documents',
          style: TextStyle(
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed:
                _loadDocuments,
            icon: const Icon(
              Icons
                  .refresh_rounded,
            ),
          ),
        ],
      ),

      // ========================================================
      // ONLY ONE ADD DOCUMENT BUTTON
      // ========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _showAddDocument,
        backgroundColor:
            const Color(0xFF2563EB),
        foregroundColor:
            Colors.white,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Add Document',
        ),
      ),

      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : _documents.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh:
                        _loadDocuments,
                    child:
                        ListView.separated(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        16,
                        18,
                        16,
                        100,
                      ),
                      itemCount:
                          _documents
                              .length,
                      separatorBuilder:
                          (
                        context,
                        index,
                      ) =>
                              const SizedBox(
                        height: 12,
                      ),
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        return _documentCard(
                          _documents[
                              index],
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          30,
          20,
          30,
          100,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFEFF6FF,
                ),
                borderRadius:
                    BorderRadius.circular(
                  25,
                ),
              ),
              child: const Icon(
                Icons
                    .folder_open_rounded,
                size: 45,
                color:
                    Color(0xFF2563EB),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'No Documents Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF111827),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Upload rental agreements, property documents, ID proofs and other important files.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color:
                    Color(0xFF64748B),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // IMPORTANT:
            // Add Document button intentionally removed here.
            // The FloatingActionButton at bottom-right
            // is the only Add Document button.
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DOCUMENT CARD
  // ============================================================

  Widget _documentCard(
    Map<String, dynamic>
        document,
  ) {
    final String name =
        document['name']
                ?.toString() ??
            'Document';

    final String type =
        document['type']
                ?.toString() ??
            'Other';

    final String fileName =
        document['file_name']
                ?.toString() ??
            '';

    final String createdAt =
        _createdAtToString(
      document['created_at'],
    );

    final extension =
        fileName.contains('.')
            ? fileName
                .split('.')
                .last
                .toLowerCase()
            : '';

    final isPdf =
        extension == 'pdf';

    final isImage =
        extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png';

    final Color iconColor =
        isPdf
            ? const Color(
                0xFFDC2626,
              )
            : isImage
                ? const Color(
                    0xFF16A34A,
                  )
                : const Color(
                    0xFF7C3AED,
                  );

    final formattedDate =
        _formatDate(
      createdAt,
    );

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap: () {
          _openDocument(
            document,
          );
        },
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color:
                  const Color(
                0xFFE5E7EB,
              ),
            ),
          ),
          child: Row(
            children: [
              // FILE ICON
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(
                  color:
                      iconColor
                          .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  isImage
                      ? Icons
                          .image_rounded
                      : isPdf
                          ? Icons
                              .picture_as_pdf_rounded
                          : Icons
                              .description_rounded,
                  color:
                      iconColor,
                  size: 27,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              // DOCUMENT DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(
                          0xFF111827,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      type,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(
                          0xFF2563EB,
                        ),
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      '$fileName • $formattedDate',
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            Color(
                          0xFF94A3B8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // MENU
              PopupMenuButton<
                  String>(
                onSelected:
                    (value) {
                  if (value ==
                      'open') {
                    _openDocument(
                      document,
                    );
                  }

                  if (value ==
                      'delete') {
                    _deleteDocument(
                      document,
                    );
                  }
                },
                itemBuilder:
                    (context) =>
                        const [
                  PopupMenuItem(
                    value:
                        'open',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .open_in_new_rounded,
                          size: 20,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Open',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value:
                        'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .delete_outline_rounded,
                          size: 20,
                          color:
                              Color(
                            0xFFDC2626,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Delete',
                        ),
                      ],
                    ),
                  ),
                ],
                icon:
                    const Icon(
                  Icons
                      .more_vert_rounded,
                  color:
                      Color(
                    0xFF64748B,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CREATED AT CONVERSION
  // ============================================================

  String _createdAtToString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    if (value is Timestamp) {
      return value
          .toDate()
          .toIso8601String();
    }

    if (value is DateTime) {
      return value
          .toIso8601String();
    }

    return value.toString();
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    String value,
  ) {
    final date =
        DateTime.tryParse(value);

    if (date == null) {
      return '';
    }

    final day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final year =
        date.year.toString();

    return '$day/$month/$year';
  }
}