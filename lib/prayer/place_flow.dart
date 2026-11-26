// Finding the place (feature 014, FR-003, FR-004, FR-004a, FR-004b, contracts/ui.md): «حدد موقعي» asks the approximate
// location only on the tap; a refusal, no reading, or the reader's choice opens the bundled city list.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'cities.dart';
import 'location_port.dart';
import 'prayer_settings.dart';
import 'prayer_strings.dart';

/// The place made from one location reading: the reading itself, the phone's zone, and the nearest listed city's name
/// and country.
Place placeFromReading(
  (double, double) reading,
  CityIndex cities,
  String phoneZone,
) {
  final city = cities.nearest(reading.$1, reading.$2);
  return Place(
    lat: double.parse(reading.$1.toStringAsFixed(3)),
    lon: double.parse(reading.$2.toStringAsFixed(3)),
    zone: phoneZone,
    name: city.ar,
    source: PlaceSource.location,
    country: city.cc,
  );
}

Place placeFromCity(City c) => Place(
  lat: c.lat,
  lon: c.lon,
  zone: c.tz,
  name: c.ar,
  source: PlaceSource.list,
  country: c.cc,
);

/// The place step: the two buttons, the failure line, and the list when it is open.
class PlaceStep extends StatefulWidget {
  const PlaceStep({
    super.key,
    required this.location,
    required this.cities,
    required this.phoneZone,
    required this.onPlace,
    this.showListAtStart = false,
  });

  final LocationPort location;
  final Future<CityIndex> Function() cities;
  final Future<String> Function() phoneZone;
  final ValueChanged<Place> onPlace;
  final bool showListAtStart;

  @override
  State<PlaceStep> createState() => _PlaceStepState();
}

class _PlaceStepState extends State<PlaceStep> {
  bool _busy = false;
  bool _failed = false;
  bool _forever = false;
  late bool _list = widget.showListAtStart;

  Future<void> _locate() async {
    setState(() => _busy = true);
    final ask = await widget.location.request();
    (double, double)? reading;
    if (ask == LocationAsk.granted) {
      reading = await widget.location.current().timeout(
        const Duration(seconds: 35),
        onTimeout: () => null,
      );
    }
    if (!mounted) return;
    if (reading != null) {
      final place = placeFromReading(
        reading,
        await widget.cities(),
        await widget.phoneZone(),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      widget.onPlace(place);
      return;
    }
    setState(() {
      _busy = false;
      _failed = true;
      _forever = ask == LocationAsk.deniedForever;
      _list = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    return Column(
      key: const ValueKey('prayer-place'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const ValueKey('place-locate'),
          onPressed: _busy ? null : _locate,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: const Text(kPlaceLocate),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('place-list'),
          onPressed: () => setState(() => _list = true),
          icon: const Icon(Icons.list),
          label: const Text(kPlaceList),
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        if (_failed) ...[
          const SizedBox(height: 12),
          Text(
            kPlaceFailed,
            key: const ValueKey('place-failed'),
            style: TextStyle(color: look.text),
          ),
          if (_forever)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const ValueKey('place-settings'),
                onPressed: widget.location.openSettings,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text(kOpenSettings),
              ),
            ),
        ],
        if (_list) ...[
          const SizedBox(height: 12),
          CityPicker(
            cities: widget.cities,
            onPick: (c) => widget.onPlace(placeFromCity(c)),
          ),
        ],
      ],
    );
  }
}

/// The search field and the matching cities (largest first when empty).
class CityPicker extends StatefulWidget {
  const CityPicker({super.key, required this.cities, required this.onPick});

  final Future<CityIndex> Function() cities;
  final ValueChanged<City> onPick;

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  CityIndex? _index;
  String _query = '';

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.cities().then((i) {
        if (mounted) setState(() => _index = i);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final index = _index;
    final found = index == null
        ? const <City>[]
        : index.search(_query, limit: 30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('city-search'),
          decoration: const InputDecoration(
            labelText: kPlaceSearch,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        if (index == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          for (final c in found)
            ListTile(
              key: ValueKey('city-${c.en}-${c.cc}'),
              minTileHeight: 48,
              contentPadding: EdgeInsets.zero,
              title: Text(c.ar, style: TextStyle(color: look.text)),
              subtitle: c.ar == c.en
                  ? null
                  : Text(c.en, style: TextStyle(color: look.textSecondary)),
              onTap: () => widget.onPick(c),
            ),
      ],
    );
  }
}
