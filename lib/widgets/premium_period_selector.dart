import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../providers/transactions_provider.dart';

class PremiumPeriodSelector extends StatelessWidget {
  final TransactionsProvider provider;

  const PremiumPeriodSelector({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: provider.filterMode == OmieFilterMode.monthly
          ? _buildMonthlySelect(context)
          : provider.filterMode == OmieFilterMode.yearly
              ? _buildYearlySelect(context)
              : _buildCustomSelector(context),
    );
  }

  Widget _buildMonthlySelect(BuildContext context) {
    final currentMonthName = DateFormat('MMMM yyyy', 'pt_BR').format(
      DateTime(provider.selectedYear, provider.selectedMonth)
    ).toUpperCase();

    return _buildSelectButton(
      context,
      icon: Icons.calendar_today_rounded,
      label: 'PERÍODO MENSAL',
      value: currentMonthName,
      onSelected: (date) => provider.setPeriod(date.month, date.year),
      items: List.generate(12, (index) {
        final date = DateTime(DateTime.now().year, DateTime.now().month - index);
        return PopupMenuItem<DateTime>(
          value: date,
          child: _buildMenuItem(
            DateFormat('MMMM yyyy', 'pt_BR').format(date).toUpperCase(),
            provider.selectedMonth == date.month && provider.selectedYear == date.year,
          ),
        );
      }),
    );
  }

  Widget _buildYearlySelect(BuildContext context) {
    return _buildSelectButton(
      context,
      icon: Icons.history_rounded,
      label: 'VISÃO ANUAL',
      value: 'ANO ${provider.selectedYear}',
      onSelected: (year) => provider.setYear(year),
      items: List.generate(5, (index) {
        final year = DateTime.now().year - index;
        return PopupMenuItem<int>(
          value: year,
          child: _buildMenuItem('ANO $year', provider.selectedYear == year),
        );
      }),
    );
  }

  Widget _buildSelectButton<T>(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required List<PopupMenuEntry<T>> items,
    required Function(T) onSelected,
  }) {
    return PopupMenuButton<T>(
      offset: const Offset(0, 55),
      elevation: 20,
      color: const Color(0xFF0F172A),
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white12)),
      onSelected: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.unfold_more_rounded, color: Colors.white54, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) => items,
    );
  }

  Widget _buildMenuItem(String text, bool isSelected) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.white12,
            shape: BoxShape.circle,
            boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.5), blurRadius: 4)] : [],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSelector(BuildContext context) {
    final start = provider.rangeStart != null ? DateFormat('dd/MM/yy').format(provider.rangeStart!) : 'Início';
    final end = provider.rangeEnd != null ? DateFormat('dd/MM/yy').format(provider.rangeEnd!) : 'Fim';

    return GestureDetector(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppTheme.textBody,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ),
              child: child!,
            );
          },
        );
        if (range != null) {
          provider.setCustomRange(range.start, range.end);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.date_range_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('INTERVALO PERSONALIZADO', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    '$start - $end',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }
}
