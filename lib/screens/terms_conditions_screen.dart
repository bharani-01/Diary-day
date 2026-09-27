import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../services/language_provider.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(lp.isTamil ? 'விதிமுறைகள் மற்றும் நிபந்தனைகள்' : 'Terms & Conditions'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              lp.isTamil ? 'KRB டெய்ரி பார்ம்ஸ் சேவை விதிமுறைகள்' : 'KRB Dairy Farms Terms of Service',
              lp.isTamil ? 'கடைசியாக புதுப்பிக்கப்பட்டது: மே 26, 2026' : 'Last Updated: May 26, 2026',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildSection(
              lp.isTamil ? '1. ஒப்பந்தத்தை ஏற்றுக்கொள்வது' : '1. Acceptance of Terms & Agreement',
              lp.isTamil 
                  ? 'இந்த KRB டெய்ரி பார்ம்ஸ் மொபைல் செயலியை நிறுவுவதன் மூலம் அல்லது பயன்படுத்துவதன் மூலம், இந்த விதிமுறைகள் மற்றும் நிபந்தனைகளுக்கு நீங்கள் முழுமையாகக் கட்டுப்பட ஒப்புக்கொள்கிறீர்கள். இந்த விதிமுறைகளில் உங்களுக்கு ஏதேனும் உடன்பாடு இல்லை எனில், இந்த செயலியை நீங்கள் பயன்படுத்தவோ அல்லது அணுகவோ கூடாது.'
                  : 'By installing, accessing, or using the KRB Dairy Farms mobile application, you agree to comply with and be bound by these Terms and Conditions. If you do not agree to all of these terms, you are prohibited from using or accessing this application.',
            ),
            _buildSection(
              lp.isTamil ? '2. பயனர் கணக்கு மற்றும் பாதுகாப்பு' : '2. Account Provisioning & Security Responsibility',
              lp.isTamil
                  ? 'விதிமுறைகளின் கீழ், பயனர் கணக்குகள் அனைத்தும் KRB டெய்ரி பார்ம்ஸ் நிர்வாகிகளால் மட்டுமே கைமுறையாக உருவாக்கப்படும். கணக்கு துவக்கப்பட்ட பின்:\n'
                    '• உங்கள் உள்நுழைவு மின்னஞ்சல் மற்றும் கடவுச்சொற்களைப் பாதுகாப்பாக வைத்திருப்பது உங்கள் முழுப் பொறுப்பாகும்.\n'
                    '• உங்கள் கணக்கின் கீழ் நடைபெறும் அனைத்துச் செயல்பாடுகளுக்கும் நீங்களே பொறுப்பாவீர்கள்.\n'
                    '• ஏதேனும் அங்கீகரிக்கப்படாத உள்நுழைவு அல்லது பாதுகாப்பு மீறல்கள் கண்டறியப்பட்டால், உடனடியாக நிர்வாகிக்குத் தெரிவிக்க வேண்டும்.'
                  : 'All user accounts are provisioned manually by KRB Dairy Farms administrators. Upon account activation:\n'
                    '• You are entirely responsible for maintaining the confidentiality of your login credentials and password.\n'
                    '• You agree to accept full responsibility for all activities, data modifications, or transactions occurring under your account.\n'
                    '• You must immediately notify our administration of any unauthorized access, security breaches, or suspicious activity.',
            ),
            _buildSection(
              lp.isTamil ? '3. தரவு துல்லியம் மற்றும் பயனர் கடமைகள்' : '3. Data Integrity & User Obligations',
              lp.isTamil
                  ? 'பயன்பாட்டின் போது நீங்கள் உள்ளீடு செய்யும் அனைத்து தரவுகளின் உண்மைத்தன்மைக்கும் துல்லியத்தன்மைக்கும் நீங்களே முழுப் பொறுப்பாவீர்கள். பால் கறவை அளவுகள், கால்நடை கொள்முதல்/விற்பனை நிதி மதிப்புகள், மற்றும் நோய்/மருத்துவக் குறிப்புகள் ஆகியவற்றில் ஏற்படும் தவறுகளால் பண்ணைக்கு ஏற்படும் இழப்புகளுக்கு இந்தச் செயலியோ அல்லது அதன் உருவாக்குநர்களோ எந்த வகையிலும் பொறுப்பாக மாட்டார்கள்.'
                  : 'You are solely responsible for verifying the accuracy and completeness of all data points entered into the system. KRB Dairy Farms and its developers assume no responsibility for business decisions, financial losses, or logistical mistakes resulting from inaccurate milk yield entries, erroneous transaction values, or incorrect medication dosages logged in the application.',
            ),
            _buildSection(
              lp.isTamil ? '4. அறிவுசார் சொத்துரிமை (Intellectual Property)' : '4. Intellectual Property Rights',
              lp.isTamil
                  ? 'KRB டெய்ரி பார்ம்ஸ் செயலியின் கட்டமைப்பு, வடிவமைப்பு, லோகோக்கள், கிராபிக்ஸ், மென்பொருள் குறியீடுகள், மற்றும் இதர குறியீடுகள் அனைத்தும் KRB டெக்னாலஜிஸ் நிறுவனத்திற்குச் சொந்தமான அறிவுசார் சொத்துரிமைகளாகும். எங்களின் முன் அனுமதி இன்றி இவற்றை நகலெடுக்கவோ, மாற்றியமைக்கவோ அல்லது வணிக ரீதியாகப் பயன்படுத்தவோ கூடாது.'
                  : 'All software codes, user interfaces, branding assets, custom logos, vector graphics, layouts, and database structures built within this application are the exclusive intellectual property of KRB Technologies. You may not copy, reverse-engineer, decompile, redistribute, or commercially exploit any proprietary code or design asset without our prior written consent.',
            ),
            _buildSection(
              lp.isTamil ? '5. உத்தரவாத மறுப்பு (Warranty Disclaimer)' : '5. Disclaimer of Warranties',
              lp.isTamil
                  ? 'இந்தச் செயலி எந்தவிதமான வெளிப்படையான அல்லது மறைமுகமான உத்தரவாதங்களும் இன்றி "உள்ளவாறே" (As Is) வழங்கப்படுகிறது. செயலி தொடர்ந்து தடங்கலின்றி இயங்கும் என்றோ அல்லது எப்போதும் பிழையற்றதாக இருக்கும் என்றோ நாங்கள் உத்தரவாதம் அளிக்கவில்லை. இணைய இணைப்புச் சிக்கல்கள் அல்லது சர்வர் பராமரிப்பு காரணமாக செயலி தற்காலிகமாகச் செயல்படாமல் போகலாம்.'
                  : 'This application is provided on an "as is" and "as available" basis without warranties of any kind, whether express or implied. We do not warrant that the application will be uninterrupted, completely secure, or entirely free of code glitches. Temporary downtime due to server maintenance or local network latency is anticipated.',
            ),
            _buildSection(
              lp.isTamil ? '6. பொறுப்பு வரம்புகள் (Limitation of Liability)' : '6. Limitation of Liability',
              lp.isTamil
                  ? 'எந்தவொரு சூழ்நிலையிலும், இந்தச் செயலியைப் பயன்படுத்தியதால் அல்லது பயன்படுத்த முடியாததால் ஏற்படும் நேரடி, மறைமுக, தற்செயலான அல்லது இழப்புகளுக்கு (லாப இழப்பு, பால் உற்பத்தி குறைவு, தரவு இழப்பு உட்பட) KRB டெய்ரி பார்ம்ஸ் அல்லது அதன் உருவாக்குநர்கள் பொறுப்பாக மாட்டார்கள்.'
                  : 'To the maximum extent permitted by applicable law, in no event shall KRB Dairy Farms or its developers be held liable for any direct, indirect, incidental, punitive, or consequential damages (including, but not limited to, loss of profits, herd yields, financial data corruption, or mobile hardware damage) arising out of the use or inability to use this software.',
            ),
            _buildSection(
              lp.isTamil ? '7. ஆளும் சட்டம் மற்றும் அதிகார வரம்பு' : '7. Governing Law & Dispute Resolution',
              lp.isTamil
                  ? 'இந்த விதிமுறைகள் இந்தியச் சட்டங்களின்படி ஆளப்படுகின்றன. இந்தச் செயலி தொடர்பாக ஏதேனும் சர்ச்சைகள் அல்லது கருத்து வேறுபாடுகள் ஏற்பட்டால், அவை தமிழ்நாடு, நாமக்கல் நீதிமன்றங்களின் பிரத்தியேக அதிகார வரம்பிற்கு உட்பட்டவை.'
                  : 'These terms and conditions shall be governed by and construed in accordance with the laws of India. Any legal actions, claims, or disputes arising out of your use of this application shall be subject to the exclusive jurisdiction of the competent courts located in Namakkal, Tamil Nadu, India.',
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'KRB Dairy Farms © 2026',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String lastUpdated, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lastUpdated,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.black45,
          ),
        ),
        const SizedBox(height: 12),
        const Divider(thickness: 1.5),
      ],
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
