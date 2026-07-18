import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/filter_controller.dart';
import '../utils/education_data.dart';

/// The rigid filtering header shown atop the Home Feed. Exposes the 4
/// mandated filters: Educational Level, Subject (dynamic on level),
/// Price Range, and Radius Distance.
class FilterHeader extends StatelessWidget {
  const FilterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<FilterController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  context: context,
                  hint: 'المرحلة التعليمية',
                  value: filter.eduLevel,
                  items: EducationData.levels,
                  onChanged: filter.setEduLevel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  context: context,
                  hint: 'المادة',
                  value: filter.subject,
                  items: filter.availableSubjects,
                  onChanged: filter.availableSubjects.isEmpty
                      ? null
                      : filter.setSubject,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'نطاق السعر: ${filter.priceRange.start.round()} - '
            '${filter.priceRange.end.round()} جنيه',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: filter.priceRange,
            min: 30,
            max: 500,
            divisions: 47,
            labels: RangeLabels(
              filter.priceRange.start.round().toString(),
              filter.priceRange.end.round().toString(),
            ),
            onChanged: filter.setPriceRange,
          ),
          const SizedBox(height: 4),
          Text(
            'نطاق البحث: ${filter.radiusKm.round()} كم',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: filter.radiusKm,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${filter.radiusKm.round()} كم',
            onChanged: filter.setRadiusKm,
          ),
          if (filter.hasActiveFilters)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: filter.reset,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('إعادة ضبط الفلاتر'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      isExpanded: true,
      hint: Text(hint, style: const TextStyle(fontSize: 13)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
