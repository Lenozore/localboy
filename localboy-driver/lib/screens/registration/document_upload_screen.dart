import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../dashboard/driver_dashboard.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String role;
  const DocumentUploadScreen({super.key, required this.role});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final Map<String, bool> _uploaded = {};

  List<Map<String, String>> get _requiredDocs {
    if (widget.role == 'driver') {
      return [
        {'key': 'aadhar', 'label': 'Aadhar Card', 'desc': 'Front and back', 'icon': '🪪'},
        {'key': 'license', 'label': 'Driving License', 'desc': 'Valid and not expired', 'icon': '🚗'},
        {'key': 'vehicle_rc', 'label': 'Vehicle RC', 'desc': 'Registration certificate', 'icon': '📋'},
        {'key': 'insurance', 'label': 'Vehicle Insurance', 'desc': 'Valid insurance policy', 'icon': '🛡️'},
        {'key': 'photo', 'label': 'Profile Photo', 'desc': 'Clear passport-size photo', 'icon': '📸'},
      ];
    } else {
      return [
        {'key': 'aadhar', 'label': 'Aadhar Card', 'desc': 'Front and back', 'icon': '🪪'},
        {'key': 'photo', 'label': 'Profile Photo', 'desc': 'Clear passport-size photo', 'icon': '📸'},
        {'key': 'certification', 'label': 'Guide Certificate', 'desc': 'Tourism dept certificate (if any)', 'icon': '📜'},
      ];
    }
  }

  Future<void> _uploadDoc(String docType) async {
    final provider = context.read<DriverProvider>();
    final success = await provider.uploadDocument(
      docType,
      'https://placeholder.localboy.app/docs/$docType',
      '$docType.pdf',
    );
    if (success) setState(() => _uploaded[docType] = true);
  }

  int get _uploadedCount => _requiredDocs.where((d) => _uploaded[d['key']!] == true).length;
  bool get _allUploaded => _uploadedCount == _requiredDocs.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Premium header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Document Verification',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          'Upload your ${widget.role} documents to get verified',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Progress indicator
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '$_uploadedCount/${_requiredDocs.length}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 8),
                      const Text('documents uploaded', style: TextStyle(fontSize: 14)),
                      const Spacer(),
                      if (_allUploaded) const Text('✅ All done!', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _requiredDocs.isEmpty ? 0 : _uploadedCount / _requiredDocs.length,
                      backgroundColor: Colors.grey[100],
                      color: const Color(0xFF2E7D32),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Doc list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = _requiredDocs[index];
                final isUploaded = _uploaded[doc['key']!] == true;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isUploaded ? Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: isUploaded
                                ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: isUploaded
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 26)
                                : Text(doc['icon']!, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc['label']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(doc['desc']!, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                            ],
                          ),
                        ),
                        if (isUploaded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Uploaded', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => _uploadDoc(doc['key']!),
                            icon: const Icon(Icons.upload_rounded, size: 16),
                            label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _requiredDocs.length,
            ),
          ),

          // Info note
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Documents will be verified by our team within 24 hours',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      // Bottom CTA
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _allUploaded
                  ? () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverDashboard()),
                        (route) => false,
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _allUploaded ? 'Continue to Dashboard →' : 'Upload all documents to continue',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _allUploaded ? Colors.white : Colors.grey[400]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
