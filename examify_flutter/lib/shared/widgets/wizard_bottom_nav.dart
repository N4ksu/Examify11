import 'package:flutter/material.dart';

class WizardBottomNav extends StatelessWidget {
  final int currentStep;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextText;
  final bool isNextLoading;
  final Function(int)? onStepTap;

  const WizardBottomNav({
    super.key,
    required this.currentStep,
    this.onBack,
    this.onNext,
    this.nextText = 'Next',
    this.isNextLoading = false,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      width: double.infinity,
      color: const Color(0xFFF1F5F9), // Scaffold background color
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              SizedBox(
                width: 120,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: onBack != null
                      ? ElevatedButton(
                          onPressed: onBack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6E4CF5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'BACK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // Indicators
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final step = index + 1;
                  final isActive = step == currentStep;
                  return InkWell(
                    onTap: onStepTap != null ? () => onStepTap!(step) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: isActive ? 12 : 10,
                        height: isActive ? 12 : 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF6E4CF5)
                              : const Color(0xFF6E4CF5).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // Next Button
              SizedBox(
                width: 120,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: onNext != null
                      ? ElevatedButton(
                          onPressed: isNextLoading ? null : onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6E4CF5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: isNextLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  nextText.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
