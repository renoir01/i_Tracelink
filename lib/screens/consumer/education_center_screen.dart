import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class EducationCenterScreen extends StatelessWidget {
  const EducationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education Center'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero Card
          _buildHeroCard(context),
          const SizedBox(height: 24),

          // What is Biofortification
          Text(
            'Learn About Biofortification',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildEducationCard(
            context,
            'What is Biofortification?',
            'Learn how breeding increases iron content in beans',
            Icons.science,
            Colors.blue,
            () => _showBiofortificationInfo(context),
          ),
          const SizedBox(height: 8),
          _buildEducationCard(
            context,
            'Health Benefits',
            'Understand the nutritional advantages',
            Icons.favorite,
            Colors.red,
            () => _showHealthBenefits(context),
          ),
          const SizedBox(height: 8),
          _buildEducationCard(
            context,
            'How to Identify',
            'Tips for recognizing authentic iron-biofortified beans',
            Icons.search,
            Colors.green,
            () => _showIdentificationTips(context),
          ),
          const SizedBox(height: 24),

          // Cooking & Nutrition
          Text(
            'Cooking & Nutrition',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildEducationCard(
            context,
            'Best Cooking Methods',
            'How to cook while preserving iron content',
            Icons.restaurant_menu,
            Colors.orange,
            () => _showCookingMethods(context),
          ),
          const SizedBox(height: 8),
          _buildEducationCard(
            context,
            'Recipe Ideas',
            'Delicious ways to prepare iron-rich beans',
            Icons.menu_book,
            Colors.purple,
            () => _showRecipes(context),
          ),
          const SizedBox(height: 8),
          _buildEducationCard(
            context,
            'Serving Suggestions',
            'Pairing beans with other foods for maximum nutrition',
            Icons.dining,
            Colors.teal,
            () => _showServingSuggestions(context),
          ),
          const SizedBox(height: 24),

          // Safety & Authenticity
          Text(
            'Safety & Authenticity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildEducationCard(
            context,
            'Verify Authenticity',
            'How to use QR codes to verify products',
            Icons.qr_code_scanner,
            Colors.indigo,
            () => _showVerificationGuide(context),
          ),
          const SizedBox(height: 8),
          _buildEducationCard(
            context,
            'Spot Counterfeits',
            'Warning signs of fake products',
            Icons.warning,
            Colors.red,
            () => _showCounterfeitGuide(context),
          ),
          const SizedBox(height: 8),
          _buildEducationCard(
            context,
            'Report Fraud',
            'How to report suspicious products',
            Icons.report,
            Colors.orange,
            () => _showFraudReporting(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.school,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 16),
          const Text(
            'Learn About Iron-Biofortified Beans',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Discover how biofortified beans combat malnutrition and improve health in Rwanda',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showBiofortificationInfo(BuildContext context) {
    _showInfoDialog(
      context,
      'What is Biofortification?',
      '''
Biofortification is the process of breeding crops to increase their nutritional value. For beans:

• Iron-biofortified beans are bred to contain 2-3x more iron than regular beans

• They contain 60-90mg of iron per 100g compared to 20-30mg in regular beans

• This is achieved through natural breeding, not genetic modification

• The beans maintain their taste, texture, and cooking properties

• Rwanda's iron-biofortified varieties include RWR 2245 and RWR 2154

This natural approach helps combat iron deficiency in communities where beans are a staple food.
      ''',
      Icons.science,
      Colors.blue,
    );
  }

  void _showHealthBenefits(BuildContext context) {
    _showInfoDialog(
      context,
      'Health Benefits',
      '''
Iron-biofortified beans provide significant health benefits:

• Prevents anemia: Adequate iron prevents iron deficiency anemia

• Boosts energy: Iron helps transport oxygen, reducing fatigue

• Supports immunity: Strengthens immune system function

• Brain development: Critical for children's cognitive development

• Maternal health: Important for pregnant and nursing mothers

• Work productivity: Reduces fatigue, improving daily performance

Regular consumption can help meet daily iron requirements, especially important in Rwanda where iron deficiency affects many women and children.
      ''',
      Icons.favorite,
      Colors.red,
    );
  }

  void _showIdentificationTips(BuildContext context) {
    _showInfoDialog(
      context,
      'How to Identify Authentic Beans',
      '''
Look for these signs of authentic iron-biofortified beans:

✓ QR code on packaging for verification
✓ Certification from Rwanda Agriculture Board
✓ Listed variety name (RWR 2245, RWR 2154, etc.)
✓ Uniform bean size and color
✓ Clean, unblemished beans
✓ Purchase from verified sellers

Always scan the QR code using this app to verify authenticity and trace the complete supply chain.

Warning signs of counterfeits:
✗ No QR code or invalid code
✗ Inconsistent bean quality
✗ Missing certification
✗ Unusually low prices
      ''',
      Icons.search,
      Colors.green,
    );
  }

  void _showCookingMethods(BuildContext context) {
    _showInfoDialog(
      context,
      'Best Cooking Methods',
      '''
To preserve iron content while cooking:

1. Soak beans overnight in clean water
2. Discard soaking water and rinse well
3. Cook in fresh water until tender
4. Add acidic foods (tomatoes, lemon) to enhance iron absorption
5. Avoid adding tea or coffee during meals

Cooking tips:
• Pressure cooking: 25-30 minutes
• Regular pot: 1.5-2 hours
• Don't overcook - beans should be tender but not mushy
• Save cooking liquid for soups (contains iron)

The iron in biofortified beans remains stable during cooking, so you can use any traditional cooking method.
      ''',
      Icons.restaurant_menu,
      Colors.orange,
    );
  }

  void _showRecipes(BuildContext context) {
    _showInfoDialog(
      context,
      'Recipe Ideas',
      '''
Try these delicious ways to enjoy iron-biofortified beans:

Traditional Rwandan:
• Isombe with beans
• Bean stew (Ibiharage)
• Mixed with plantains

International fusion:
• Bean curry with vegetables
• Bean salad with fresh greens
• Bean soup with tomatoes
• Mashed beans (Refried beans style)

Meal ideas:
• Breakfast: Bean porridge
• Lunch: Bean and vegetable stew
• Dinner: Beans with rice and greens
• Snacks: Roasted beans

Tip: Pair with vitamin C-rich foods like tomatoes, peppers, or citrus fruits to boost iron absorption by up to 3x!
      ''',
      Icons.menu_book,
      Colors.purple,
    );
  }

  void _showServingSuggestions(BuildContext context) {
    _showInfoDialog(
      context,
      'Serving Suggestions',
      '''
Maximize nutrition by pairing beans with:

Best combinations for iron absorption:
• Tomatoes (vitamin C enhances iron uptake)
• Bell peppers (rich in vitamin C)
• Leafy greens (additional iron source)
• Citrus fruits (boost absorption)
• Sweet potatoes (vitamin A helps)

Foods to avoid with beans:
✗ Tea or coffee (within 1 hour of eating)
✗ Excessive dairy (calcium interferes with iron)
✗ High-fiber supplements (can reduce absorption)

Serving sizes:
• Adults: 1-1.5 cups cooked beans per meal
• Children: 0.5-1 cup per meal
• Pregnant women: 1.5-2 cups per meal

Aim for beans 3-4 times per week for optimal iron intake.
      ''',
      Icons.dining,
      Colors.teal,
    );
  }

  void _showVerificationGuide(BuildContext context) {
    _showInfoDialog(
      context,
      'How to Verify Products',
      '''
Follow these steps to verify authenticity:

1. Open iTraceLink app
2. Tap "Scan Product" button
3. Point camera at QR code on packaging
4. Wait for instant verification
5. View complete supply chain information

What you'll see:
✓ Product verification status
✓ Origin farm/cooperative
✓ Iron content certification
✓ Complete journey from seed to table
✓ Seller verification

The QR code connects you directly to our blockchain-secured database, ensuring complete transparency and authenticity.

If verification fails, DO NOT purchase the product and report it through the app.
      ''',
      Icons.qr_code_scanner,
      Colors.indigo,
    );
  }

  void _showCounterfeitGuide(BuildContext context) {
    _showInfoDialog(
      context,
      'Spot Counterfeit Products',
      '''
Warning signs of fake iron-biofortified beans:

🚫 Missing or invalid QR code
🚫 No certification documents
🚫 Price significantly below market rate
🚫 Inconsistent bean quality
🚫 Unknown or unverified seller
🚫 Packaging looks tampered or poor quality
🚫 No variety name listed
🚫 Seller avoids scanning QR code

Protect yourself:
• Always scan before buying
• Buy from verified sellers only
• Check for Rwanda Agriculture Board seal
• Report suspicious products
• Trust your instincts

Remember: If it seems too good to be true, it probably is. Authentic iron-biofortified beans have a traceable supply chain.
      ''',
      Icons.warning,
      Colors.red,
    );
  }

  void _showFraudReporting(BuildContext context) {
    _showInfoDialog(
      context,
      'Report Fraud',
      '''
If you encounter counterfeit products:

In the app:
1. Go to purchase history
2. Select the suspicious scan
3. Tap "Report Fraud"
4. Provide details and photos
5. Submit report

What happens next:
• Your report is sent to authorities
• Investigation is initiated
• Seller may be flagged
• You'll receive updates on action taken

Contact authorities:
• Rwanda Agriculture Board: [Number]
• Local police
• Consumer protection office

Your reports help protect other consumers and maintain supply chain integrity.

All reports are confidential and you may remain anonymous if preferred.
      ''',
      Icons.report,
      Colors.orange,
    );
  }

  void _showInfoDialog(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
