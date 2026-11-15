import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

const kDefaultOfferMessage = 'Jestem zainteresowany. Proszę o kontakt.';

/// Kiedy firma może zacząć — wartości zapisywane w ofercie (pole `when`).
const kOfferWhen = {
  'today': 'Dziś',
  'tomorrow': 'Jutro',
  'week': 'W tym tygodniu',
  'agree': 'Do uzgodnienia',
};

typedef OfferDraft = ({String message, int? price, int? priceTo, String? when});

/// Cena oferty do wyświetlenia: „250 zł”, „250–400 zł” albo null.
String? offerPriceLabel(Map<String, dynamic> offer) {
  final p = offer['price'];
  if (p is! int) return null;
  final to = offer['priceTo'];
  return to is int && to > p ? '$p–$to zł' : '$p zł';
}

const _kTemplateKey = 'offer_template';

/// Dialog oferty: treść (z zapamiętanego szablonu firmy) + opcjonalna cena (od–do) i termin.
Future<OfferDraft?> showOfferDialog(BuildContext context, String clientName) async {
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}
  if (!context.mounted) return null;
  final ctrl = TextEditingController(
      text: prefs?.getString(_kTemplateKey) ?? kDefaultOfferMessage);
  var saveTemplate = false;
  final priceCtrl = TextEditingController();
  final priceToCtrl = TextEditingController();
  String? when;
  String? error;

  return showDialog<OfferDraft>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(kGapL, kGapL, kGapL, kGapM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer_outlined, color: cDarkBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        clientName.isEmpty ? 'Oferta' : 'Oferta dla: $clientName',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: kGapM),
              TextField(
                controller: ctrl,
                maxLines: 6,
                minLines: 4,
                maxLength: 400,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Co oferujesz, jak możesz pomóc…',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(kRadius))),
                  contentPadding: EdgeInsets.all(kGapM),
                ),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: saveTemplate,
                onChanged: (v) => setState(() => saveTemplate = v ?? false),
                title: const Text('Zapamiętaj tę treść jako mój szablon'),
              ),
              const Text('Cena (opcjonalnie)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: kGapXs),
              Row(
                children: [
                  Expanded(child: _priceField(priceCtrl, 'od')),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–'),
                  ),
                  Expanded(child: _priceField(priceToCtrl, 'do')),
                  const SizedBox(width: 8),
                  const Text('zł'),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Kiedy możesz zacząć?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: kGapXs),
              Wrap(
                spacing: kGapS,
                runSpacing: kGapS,
                children: [
                  for (final e in kOfferWhen.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: when == e.key,
                      onSelected: (s) => setState(() => when = s ? e.key : null),
                    ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 8),
              const Text('Klient zobaczy ofertę przy swoim zgłoszeniu i porówna ją z innymi.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: kGapL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Anuluj'),
                    ),
                  ),
                  const SizedBox(width: kGapM),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: cDarkBlue),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Wyślij ofertę',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        final message = ctrl.text.trim();
                        final price = int.tryParse(priceCtrl.text.trim());
                        final priceTo = int.tryParse(priceToCtrl.text.trim());
                        if (message.isEmpty) {
                          setState(() => error = 'Napisz treść oferty');
                          return;
                        }
                        if (priceTo != null && price == null) {
                          setState(() => error = 'Podaj cenę „od”');
                          return;
                        }
                        if (price != null && priceTo != null && priceTo < price) {
                          setState(() => error = 'Cena „do” musi być wyższa niż „od”');
                          return;
                        }
                        if (saveTemplate) prefs?.setString(_kTemplateKey, message);
                        Navigator.pop(ctx, (
                          message: message,
                          price: price,
                          priceTo: priceTo != null && priceTo > (price ?? 0) ? priceTo : null,
                          when: when,
                        ));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _priceField(TextEditingController c, String hint) => TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(kRadius))),
      ),
    );
