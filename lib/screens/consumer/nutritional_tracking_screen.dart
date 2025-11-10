import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class NutritionalTrackingScreen extends StatelessWidget {
  const NutritionalTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userModel?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutritional Tracking'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.consumerPurchasesCollection)
            .where('consumerId', isEqualTo: userId)
            .where('quantityPurchased', isGreaterThan: 0)
            .snapshots(),
        builder: (context, snapshot) {
          final purchases = snapshot.data?.docs ?? [];

          // Calculate total iron intake
          double totalIronIntake = 0;
          double totalBeansConsumed = 0;

          for (var doc in purchases) {
            final data = doc.data() as Map<String, dynamic>;
            final quantity = (data['quantityPurchased'] ?? 0).toDouble();
            totalBeansConsumed += quantity;
            // Average iron content: 80mg per 100g
            totalIronIntake += (quantity * 1000 * 80) / 100; // Convert to mg
          }

          final dailyIronGoal = 18.0; // mg per day (adult woman)
          final daysSupplied = totalIronIntake / dailyIronGoal;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Iron Intake Card
                _buildIronIntakeCard(totalIronIntake, dailyIronGoal),
                const SizedBox(height: 16),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Beans',
                        '${totalBeansConsumed.toStringAsFixed(1)} kg',
                        Icons.scale,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Days Supplied',
                        '${daysSupplied.toStringAsFixed(0)} days',
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Health Benefits
                Text(
                  'Health Benefits',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildHealthBenefits(),
                const SizedBox(height: 24),

                // Daily Recommendations
                Text(
                  'Daily Iron Recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildIronRecommendations(),
                const SizedBox(height: 24),

                // Cooking Tips
                Text(
                  'Cooking Tips',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildCookingTips(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIronIntakeCard(double totalIron, double dailyGoal) {
    final percentage = (totalIron / dailyGoal * 100).clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Iron Intake',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'From Iron-Biofortified Beans',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Iron',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${totalIron.toStringAsFixed(0)} mg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Daily Goal',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${dailyGoal.toStringAsFixed(0)} mg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBenefits() {
    return Column(
      children: [
        _buildBenefitCard(
          'Prevents Anemia',
          'Iron-rich beans help prevent iron deficiency anemia',
          Icons.favorite,
          Colors.red,
        ),
        const SizedBox(height: 8),
        _buildBenefitCard(
          'Boosts Energy',
          'Adequate iron levels improve energy and reduce fatigue',
          Icons.bolt,
          Colors.orange,
        ),
        const SizedBox(height: 8),
        _buildBenefitCard(
          'Supports Immunity',
          'Iron strengthens immune system function',
          Icons.shield,
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildBenefitCard(
          'Child Development',
          'Critical for cognitive development in children',
          Icons.child_care,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildBenefitCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIronRecommendations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecommendationRow('Adult Women', '18 mg/day'),
            _buildRecommendationRow('Adult Men', '8 mg/day'),
            _buildRecommendationRow('Pregnant Women', '27 mg/day'),
            _buildRecommendationRow('Children (4-8 yrs)', '10 mg/day'),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '100g of iron-biofortified beans provides 60-90mg of iron',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationRow(String category, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category,
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookingTips() {
    return Column(
      children: [
        _buildTipCard(
          'Soak Before Cooking',
          'Soak beans overnight to improve iron absorption',
          Icons.water_drop,
        ),
        const SizedBox(height: 8),
        _buildTipCard(
          'Cook with Vitamin C',
          'Add tomatoes or lemon juice to enhance iron absorption',
          Icons.restaurant,
        ),
        const SizedBox(height: 8),
        _buildTipCard(
          'Avoid Tea with Meals',
          'Wait 1 hour after eating beans before drinking tea',
          Icons.coffee,
        ),
        const SizedBox(height: 8),
        _buildTipCard(
          'Proper Storage',
          'Store in cool, dry place to maintain nutritional value',
          Icons.inventory_2,
        ),
      ],
    );
  }

  Widget _buildTipCard(String title, String description, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
