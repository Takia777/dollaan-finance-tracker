import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import '../utils/format.dart';

class NewGoalScreen extends StatefulWidget {
  const NewGoalScreen({super.key});

  @override
  State<NewGoalScreen> createState() => _NewGoalScreenState();
}

class _NewGoalScreenState extends State<NewGoalScreen> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  DateTime? _date;
  Uint8List? _image;
  String _ext = 'jpg';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _image = bytes;
      _ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (d != null) setState(() => _date = d);
  }

  /// Rekomendasi tabungan per hari agar target tercapai tepat waktu.
  String? get _hint {
    final target = parseAmountInput(_target.text);
    if (target == null || _date == null) return null;
    final days = _date!.difference(dayOnly(DateTime.now())).inDays;
    if (days <= 0) return null;
    final perDay = (target / days / 1000).ceil() * 1000;
    return 'Save ${rupiah(perDay)}/day → done by ${shortDate(_date!)}';
  }

  Future<void> _save() async {
    final target = parseAmountInput(_target.text);
    if (_name.text.trim().isEmpty || target == null || target <= 0) {
      showSnack(context, 'Isi nama goal dan target nominalnya.');
      return;
    }
    setState(() => _busy = true);
    try {
      await app.createGoal(
        name: _name.text.trim(),
        target: target,
        targetDate: _date,
        imageBytes: _image,
        imageExt: _ext,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Goal created! Let\'s start saving 💪');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, friendlyError(e));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = _hint;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(title: 'New goal', backIcon: Icons.close_rounded),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.putih,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.ungu.o(0.6), width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _image != null
                          ? Image.memory(_image!, fit: BoxFit.cover, width: double.infinity)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const IconBubble(icon: Icons.image_rounded, color: AppColors.ungu, size: 48),
                                const SizedBox(height: 8),
                                Text('Add a picture of your goal', style: ts(14, FontWeight.w700)),
                                Text('PNG or JPG · it keeps you motivated!',
                                    style: ts(11, FontWeight.w500, AppColors.muted)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Goal name',
                    controller: _name,
                    icon: Icons.track_changes_rounded,
                    hint: 'Sneakers #3',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Target amount',
                          controller: _target,
                          icon: Icons.payments_rounded,
                          keyboardType: TextInputType.number,
                          hint: '800000',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('Target date'),
                            GestureDetector(
                              onTap: _pickDate,
                              child: AppCard(
                                radius: 16,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.muted),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _date == null ? 'Pick date' : shortDate(_date!),
                                        overflow: TextOverflow.ellipsis,
                                        style: ts(14, FontWeight.w600, _date == null ? AppColors.muted : AppColors.unguTua),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 14),
                    AppCard(
                      radius: 16,
                      color: AppColors.tosca.o(0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.tosca),
                          const SizedBox(width: 8),
                          Expanded(child: Text(hint, style: ts(12, FontWeight.w600, AppColors.tosca))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryButton(label: 'Create goal', icon: Icons.check_rounded, loading: _busy, onTap: _save),
            ),
          ],
        ),
      ),
    );
  }
}
