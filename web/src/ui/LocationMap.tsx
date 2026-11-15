import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useEffect, useRef } from 'preact/hooks';
import type { LatLng } from '../data/requests.ts';

const WARSAW: [number, number] = [52.237049, 21.017532];

const pin = L.divIcon({
  className: 'map-pin',
  html: '<svg viewBox="0 0 24 32" width="32" height="42" aria-hidden="true"><path d="M12 0C5.4 0 0 5.4 0 12c0 9 12 20 12 20s12-11 12-20C24 5.4 18.6 0 12 0z" fill="#ED285B"/><circle cx="12" cy="12" r="4.5" fill="#fff"/></svg>',
  iconSize: [32, 42],
  iconAnchor: [16, 42],
});

/** Mapa OSM z pinezką; kliknięcie wskazuje miejsce. [focusKey] zmienia się, gdy trzeba przesunąć widok. */
export function LocationMap({
  value,
  onPick,
  focusKey,
  label,
}: {
  value: LatLng | null;
  onPick: (p: LatLng) => void;
  focusKey: number;
  label: string;
}) {
  const el = useRef<HTMLDivElement>(null);
  const map = useRef<L.Map | null>(null);
  const marker = useRef<L.Marker | null>(null);
  const pick = useRef(onPick);
  pick.current = onPick;

  useEffect(() => {
    if (!el.current) return;
    const m = L.map(el.current, {
      center: value ? [value.lat, value.lng] : WARSAW,
      zoom: value ? 13 : 6,
      scrollWheelZoom: false,
    });
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(m);
    m.on('click', (e: L.LeafletMouseEvent) => pick.current({ lat: e.latlng.lat, lng: e.latlng.lng }));
    map.current = m;
    return () => {
      m.remove();
      map.current = null;
      marker.current = null;
    };
  }, []);

  useEffect(() => {
    const m = map.current;
    if (!m) return;
    if (!value) {
      marker.current?.remove();
      marker.current = null;
      return;
    }
    if (marker.current) marker.current.setLatLng([value.lat, value.lng]);
    else marker.current = L.marker([value.lat, value.lng], { icon: pin, keyboard: false }).addTo(m);
  }, [value?.lat, value?.lng]);

  useEffect(() => {
    if (focusKey && value) map.current?.setView([value.lat, value.lng], Math.max(map.current.getZoom(), 13));
  }, [focusKey]);

  return <div class="map" ref={el} role="region" aria-label={label} />;
}
