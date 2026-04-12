import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choisissez votre forfait',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.pitchShort,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Plans
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Free Plan
                  _buildPlanCard(
                    context,
                    title: AppStrings.freePlan,
                    price: 'Gratuit',
                    description: 'Pour découvrir My Leads',
                    features: [
                      '25 contacts max',
                      'Scan carte de visite',
                      'Recherche basique',
                      '5 rappels actifs',
                    ],
                    isPopular: false,
                    isCurrent: true,
                  ),
                  const SizedBox(height: 16),

                  // Premium Plan
                  _buildPlanCard(
                    context,
                    title: AppStrings.premiumPlan,
                    price: '2.99€',
                    period: '/ mois',
                    description: 'Pour les professionnels exigeants',
                    features: [
                      'Contacts illimités',
                      'Scan OCR + QR + NFC',
                      'IA enrichissement automatique',
                      'Rappels illimités',
                      'Export CSV / CRM',
                      'Synchronisation cloud',
                      'Support prioritaire',
                    ],
                    isPopular: true,
                  ),
                  const SizedBox(height: 16),

                  // Business Plan
                  _buildPlanCard(
                    context,
                    title: AppStrings.businessPlan,
                    price: '5.99€',
                    period: '/ utilisateur / mois',
                    description: 'Pour les équipes commerciales',
                    features: [
                      'Tout Premium inclus',
                      'Gestion multi-utilisateurs',
                      'Dashboard équipe',
                      'Intégrations CRM avancées',
                      'API access',
                      'Analytics avancés',
                      'IA scoring leads',
                      'Onboarding dédié',
                    ],
                    isPopular: false,
                  ),

                  const SizedBox(height: 24),

                  // Payment methods
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.06),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MOYENS DE PAIEMENT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _paymentChip('Carte bancaire'),
                            _paymentChip('PayPal'),
                            _paymentChip('Apple Pay'),
                            _paymentChip('Google Pay'),
                            _paymentChip('Mobile Money'),
                            _paymentChip('Virement'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Paiement sécurisé. Annulation à tout moment.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    String? period,
    required String description,
    required List<String> features,
    required bool isPopular,
    bool isCurrent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPopular ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: isPopular
            ? Border.all(color: AppColors.accent, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? AppColors.accent.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.08),
            blurRadius: isPopular ? 30 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isPopular ? Colors.white : AppColors.textDark,
                ),
              ),
              if (isPopular) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'POPULAIRE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              if (isCurrent) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTUEL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isPopular ? AppColors.accent : AppColors.primary,
                ),
              ),
              if (period != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPopular
                          ? Colors.white.withOpacity(0.5)
                          : AppColors.textMid,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: isPopular
                  ? Colors.white.withOpacity(0.5)
                  : AppColors.textMid,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: isPopular ? AppColors.accent : AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          color: isPopular ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          if (!isCurrent)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Abonnement $title bientôt disponible !'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPopular ? AppColors.accent : AppColors.primary,
                  foregroundColor:
                      isPopular ? AppColors.primary : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Choisir $title',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
