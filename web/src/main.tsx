import { render } from 'preact';
import { App } from './app.tsx';
import { missingConfig } from './firebase.ts';
import { ConfigMissing } from './pages/Static.tsx';
import { interceptLinks } from './router.ts';
import { initSession } from './session.ts';
import './styles.css';

const root = document.getElementById('app')!;

if (missingConfig.length) {
  render(<ConfigMissing keys={missingConfig} />, root);
} else {
  interceptLinks();
  render(<App />, root);
  void initSession();
}
