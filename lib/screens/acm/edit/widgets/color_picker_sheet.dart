import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> showColorPickerSheet(
  BuildContext context, {
  String? initialHex,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ColorPickerSheet(initialHex: initialHex),
  );
}

Color? _parseHex(String? s) {
  if (s == null) return null;
  final h = s.replaceAll('#', '').trim();
  if (h.length != 6) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

String _toHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class _ColorPickerSheet extends StatefulWidget {
  const _ColorPickerSheet({this.initialHex});
  final String? initialHex;

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSVColor _hsv;
  late final TextEditingController _hex;

  @override
  void initState() {
    super.initState();
    final start = _parseHex(widget.initialHex) ?? const Color(0xFF6C5CE7);
    _hsv = HSVColor.fromColor(start);
    _hex = TextEditingController(text: _toHex(start));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(HSVColor v) {
    setState(() => _hsv = v);
    _hex.value = TextEditingValue(
      text: _toHex(v.toColor()),
      selection: TextSelection.collapsed(offset: 7),
    );
  }

  void _onHexChanged(String s) {
    final c = _parseHex(s);
    if (c != null) setState(() => _hsv = HSVColor.fromColor(c));
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    final h = _hsv.hue, s = _hsv.saturation, v = _hsv.value;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _hex,
                    onChanged: _onHexChanged,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'HEX',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SvArea(
              hue: h,
              s: s,
              v: v,
              onChanged: (ns, nv) => _set(_hsv.withSaturation(ns).withValue(nv)),
            ),
            const SizedBox(height: 16),

            _label('Оттенок'),
            _GradSlider(
              value: h / 360,
              colors: [
                for (var i = 0; i <= 6; i++)
                  HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
              ],
              onChanged: (x) => _set(_hsv.withHue((x * 360).clamp(0, 359.99))),
            ),
            _label('Насыщенность'),
            _GradSlider(
              value: s,
              colors: [
                HSVColor.fromAHSV(1, h, 0, v).toColor(),
                HSVColor.fromAHSV(1, h, 1, v).toColor(),
              ],
              onChanged: (x) => _set(_hsv.withSaturation(x)),
            ),
            _label('Яркость (затемнение)'),
            _GradSlider(
              value: v,
              colors: [
                Colors.black,
                HSVColor.fromAHSV(1, h, s, 1).toColor(),
              ],
              onChanged: (x) => _set(_hsv.withValue(x)),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _toHex(color)),
                    child: const Text('Выбрать'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text(t, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
}

class _SvArea extends StatelessWidget {
  const _SvArea({
    required this.hue,
    required this.s,
    required this.v,
    required this.onChanged,
  });
  final double hue, s, v;
  final void Function(double s, double v) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      const h = 200.0;

      void handle(Offset p) => onChanged(
            (p.dx / w).clamp(0.0, 1.0),
            1 - (p.dy / h).clamp(0.0, 1.0),
          );

      return GestureDetector(
        onPanDown: (d) => handle(d.localPosition),
        onPanUpdate: (d) => handle(d.localPosition),
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                    ),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Color(0x00FFFFFF)],
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Colors.black],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: s * w - 11,
                top: (1 - v) * h - 11,
                child: IgnorePointer(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HSVColor.fromAHSV(1, hue, s, v).toColor(),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _GradSlider extends StatelessWidget {
  const _GradSlider({
    required this.value,
    required this.colors,
    required this.onChanged,
  });
  final double value;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      void handle(Offset p) => onChanged((p.dx / w).clamp(0.0, 1.0));

      return GestureDetector(
        onPanDown: (d) => handle(d.localPosition),
        onPanUpdate: (d) => handle(d.localPosition),
        child: SizedBox(
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(colors: colors),
                ),
              ),
              Positioned(
                left: value * w - 12,
                child: IgnorePointer(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.black26, width: 1),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}