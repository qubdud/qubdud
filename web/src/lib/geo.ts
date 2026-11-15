import type { LatLng } from '../data/requests.ts';

const NOMINATIM = 'https://nominatim.openstreetmap.org';

/** Miejscowość dla punktu (jak _cityAt w apce: city/town/village/municipality). */
export async function reverseCity(p: LatLng): Promise<string | null> {
  try {
    const res = await fetch(`${NOMINATIM}/reverse?format=jsonv2&lat=${p.lat}&lon=${p.lng}&accept-language=pl&zoom=14`);
    if (!res.ok) return null;
    const a = (await res.json())?.address ?? {};
    for (const k of ['city', 'town', 'village', 'municipality']) {
      if (typeof a[k] === 'string' && a[k]) return a[k];
    }
  } catch {
    // brak sieci albo limit Nominatim — miejscowość zostaje do wpisania
  }
  return null;
}

/** Pierwszy wynik wyszukiwania miejscowości w Polsce (jak _onCityChanged w apce). */
export async function searchPlace(q: string): Promise<LatLng | null> {
  try {
    const res = await fetch(
      `${NOMINATIM}/search?format=jsonv2&limit=1&addressdetails=1&accept-language=pl&q=${encodeURIComponent(`${q}, Polska`)}`,
    );
    if (!res.ok) return null;
    const r = (await res.json())?.[0];
    const lat = parseFloat(r?.lat);
    const lng = parseFloat(r?.lon);
    return Number.isFinite(lat) && Number.isFinite(lng) ? { lat, lng } : null;
  } catch {
    return null;
  }
}

export function currentPosition(): Promise<LatLng> {
  return new Promise((resolve, reject) => {
    if (!('geolocation' in navigator)) {
      reject(new Error('Ta przeglądarka nie udostępnia lokalizacji — ustaw miejsce na mapie'));
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (p) => resolve({ lat: p.coords.latitude, lng: p.coords.longitude }),
      (e) =>
        reject(
          new Error(
            e.code === e.PERMISSION_DENIED
              ? 'Brak zgody na lokalizację — ustaw miejsce na mapie albo zezwól w ustawieniach przeglądarki'
              : 'Nie udało się ustalić lokalizacji — ustaw ją na mapie',
          ),
        ),
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 60000 },
    );
  });
}
