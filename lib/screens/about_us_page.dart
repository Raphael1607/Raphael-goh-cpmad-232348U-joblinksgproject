import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const String appName = 'JobLinkSG';
  static const String companyName = 'JobLinkSG (Student Project)';
  static const String developerName = 'Raphael Goh'; 
  static const String supportPhone = '61234567';        
  static const String supportEmail = 'support@example.com';

  Future<void> _launchTel(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: Uri.encodeQueryComponent('subject=$appName Feedback'),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.work_outline, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appName,
                              style: textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Find jobs. Apply fast. Track progress.',
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 16),

               
                _sectionTitle(context, Icons.info_outline, 'About this app'),
                const SizedBox(height: 8),
                const Text(
                  'JobLinkSG helps students discover internships and gigs in Singapore. '
                  'Use Swipe to Apply (right to apply, left to reject) to browse quickly, '
                  'track all applications in one place, and build a simple portfolio for each company '
                  'with photos, roles, responsibilities, and achievements.',
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 16),

              
                _sectionTitle(context, Icons.apartment_outlined, 'Company / Project'),
                const SizedBox(height: 8),
                Text(companyName),

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 16),

                _sectionTitle(context, Icons.person_outline, 'Developer'),
                const SizedBox(height: 8),
                Text(developerName),

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 16),

            
                _sectionTitle(context, Icons.support_agent_outlined, 'Contact us'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchTel(supportPhone),
                        icon: const Icon(Icons.call_outlined),
                        label: Text('Call $supportPhone'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchEmail(supportEmail),
                        icon: const Icon(Icons.email_outlined),
                        label: const Text('Email us'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.blueGrey.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              
              ],
            ),
          ),
        ),
      ),
    );
  }
}
