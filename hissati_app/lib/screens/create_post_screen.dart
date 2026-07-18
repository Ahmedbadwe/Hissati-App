import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import '../models/app_user.dart';
import '../models/tutor_offer.dart';
import '../models/parent_request.dart';
import '../services/location_service.dart';
import '../utils/education_data.dart';

class CreatePostScreen extends StatefulWidget {
  final AppUser currentUser;
  const CreatePostScreen({super.key, required this.currentUser});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _eduLevel;
  String? _subject;
  final _priceCenterController = TextEditingController();
  final _pricePrivateController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _availableTimesController = TextEditingController();

  bool _isSubmitting = false;

  bool get _isTutor => widget.currentUser.role == UserRole.tutor;

  @override
  void dispose() {
    _priceCenterController.dispose();
    _pricePrivateController.dispose();
    _maxBudgetController.dispose();
    _descriptionController.dispose();
    _availableTimesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final position = await LocationService.instance.getCurrentPosition();
      final geo = GeoFlutterFire().point(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final geoPoint = GeoPoint(position.latitude, position.longitude);

      if (_isTutor) {
        final offer = TutorOffer(
          offerId: '',
          tutorUid: widget.currentUser.uid,
          tutorName: widget.currentUser.fullName,
          tutorPhone: widget.currentUser.phoneNumber,
          eduLevel: _eduLevel!,
          subject: _subject!,
          priceCenter: int.parse(_priceCenterController.text),
          pricePrivate: int.parse(_pricePrivateController.text),
          availableTimes: _availableTimesController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          locationGeo: geoPoint,
          createdAt: DateTime.now(),
        );
        await FirebaseFirestore.instance
            .collection('tutor_offers')
            .add(offer.toMap(geo.data));
      } else {
        final request = ParentRequest(
          requestId: '',
          parentUid: widget.currentUser.uid,
          parentName: widget.currentUser.fullName,
          parentPhone: widget.currentUser.phoneNumber,
          subject: _subject!,
          eduLevel: _eduLevel!,
          maxBudget: int.parse(_maxBudgetController.text),
          descriptionText: _descriptionController.text.trim(),
          locationGeo: geoPoint,
          createdAt: DateTime.now(),
        );
        await FirebaseFirestore.instance
            .collection('parent_requests')
            .add(request.toMap(geo.data));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء النشر: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects =
        _eduLevel == null ? <String>[] : EducationData.subjectsFor(_eduLevel!);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isTutor ? 'إعلان تدريس جديد' : 'طلب درس خصوصي جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _eduLevel,
              decoration: const InputDecoration(labelText: 'المرحلة التعليمية'),
              items: EducationData.levels
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() {
                _eduLevel = v;
                _subject = null;
              }),
              validator: (v) => v == null ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(labelText: 'المادة'),
              items: subjects
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: subjects.isEmpty
                  ? null
                  : (v) => setState(() => _subject = v),
              validator: (v) => v == null ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            if (_isTutor) ...[
              TextFormField(
                controller: _priceCenterController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر الحصة (مجموعة/سنتر)',
                  suffixText: 'جنيه',
                ),
                validator: _numberValidator,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pricePrivateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر الحصة (خصوصي)',
                  suffixText: 'جنيه',
                ),
                validator: _numberValidator,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _availableTimesController,
                decoration: const InputDecoration(
                  labelText: 'المواعيد المتاحة (افصل بينها بفاصلة)',
                  hintText: 'مثال: السبت 5م, الاثنين 7م',
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _maxBudgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الميزانية القصوى للحصة',
                  suffixText: 'جنيه',
                ),
                validator: _numberValidator,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل إضافية عن الطلب',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('نشر'),
            ),
          ],
        ),
      ),
    );
  }

  String? _numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'مطلوب';
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return 'قيمة غير صحيحة';
    return null;
  }
}
