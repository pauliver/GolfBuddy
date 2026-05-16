// Phone screens — 402×874, paper light theme.
// Six screens, all share the .phone-screen base.

const PH_HEADER_H = 50; // below status bar

// ─────────────────────────────────────────────────────────────
// Small reusable bits
// ─────────────────────────────────────────────────────────────
function PhoneStatus({ time = '9:41' }) {
  return <IOSStatusBar time={time}/>;
}
function PhoneEyebrow({ children }) {
  return <div style={{ fontFamily: 'var(--mono)', fontSize: 11, letterSpacing: 1.6,
    color: 'var(--ink-mute)', textTransform: 'uppercase' }}>{children}</div>;
}
function PhoneTabs({ active = 'home', onChange }) {
  const tabs = [
    { id: 'home',    label: 'Round',   icon: 'flag' },
    { id: 'history', label: 'History', icon: 'book' },
    { id: 'stats',   label: 'Stats',   icon: 'chart' },
    { id: 'courses', label: 'Courses', icon: 'map' },
  ];
  const Icon = ({ k }) => {
    const c = 'currentColor';
    if (k === 'flag') return <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M6 21V4M6 4L18 8L13 12L18 16L6 16" stroke={c} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/></svg>;
    if (k === 'book') return <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M4 5C4 4 5 3 6 3H19V18H6C5 18 4 19 4 20M4 5V20M4 5C4 6 5 7 6 7H17M4 20C4 21 5 22 6 22H19" stroke={c} strokeWidth="1.4" strokeLinecap="round"/></svg>;
    if (k === 'chart') return <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M3 19L9 12L13 16L21 6" stroke={c} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/><circle cx="9" cy="12" r="1.4" fill={c}/><circle cx="13" cy="16" r="1.4" fill={c}/><circle cx="21" cy="6" r="1.4" fill={c}/></svg>;
    return <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M3 6L9 4L15 6L21 4V18L15 20L9 18L3 20V6Z" stroke={c} strokeWidth="1.4" strokeLinejoin="round"/><path d="M9 4V18M15 6V20" stroke={c} strokeWidth="1.4"/></svg>;
  };
  return (
    <div style={{ height: 78, paddingBottom: 18, paddingTop: 8,
      borderTop: '1px solid var(--line-soft)', background: 'var(--paper)',
      display: 'flex', justifyContent: 'space-around', alignItems: 'flex-start' }}>
      {tabs.map(t => {
        const on = t.id === active;
        return (
          <button key={t.id} onClick={() => onChange && onChange(t.id)}
            style={{ background: 'none', border: 'none', cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
              color: on ? 'var(--moss)' : 'var(--ink-mute)',
              padding: '6px 12px' }}>
            <Icon k={t.icon}/>
            <span style={{ fontFamily: 'var(--sans)', fontSize: 10, fontWeight: on ? 600 : 500, letterSpacing: 0.2 }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// Hole map illustration — top-down svg, used on home + round detail
function HoleMap({ height = 280, par = 4, ballPos = 0.55 }) {
  // ballPos: 0 = tee, 1 = green
  return (
    <svg viewBox="0 0 320 280" style={{ width: '100%', height, display: 'block' }}>
      <defs>
        <radialGradient id="ph-grn" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#94B27E" stopOpacity="0.8"/>
          <stop offset="100%" stopColor="#6B8E5A" stopOpacity="0.3"/>
        </radialGradient>
        <linearGradient id="ph-fwy" x1="0" y1="1" x2="0" y2="0">
          <stop offset="0%" stopColor="#3D5A3B" stopOpacity="0.10"/>
          <stop offset="60%" stopColor="#6B8E5A" stopOpacity="0.20"/>
          <stop offset="100%" stopColor="#94B27E" stopOpacity="0.25"/>
        </linearGradient>
        <pattern id="rough" patternUnits="userSpaceOnUse" width="6" height="6" patternTransform="rotate(35)">
          <line x1="0" y1="0" x2="0" y2="6" stroke="#3D5A3B" strokeOpacity="0.15" strokeWidth="1"/>
        </pattern>
      </defs>
      {/* rough background */}
      <rect width="320" height="280" fill="url(#rough)"/>
      {/* fairway shape */}
      <path d="M 130 260 C 90 220, 220 200, 220 130 C 220 80, 140 80, 140 30"
        fill="none" stroke="url(#ph-fwy)" strokeWidth="78" strokeLinecap="round"/>
      <path d="M 130 260 C 90 220, 220 200, 220 130 C 220 80, 140 80, 140 30"
        fill="none" stroke="#6B8E5A" strokeOpacity="0.18" strokeWidth="62" strokeLinecap="round"/>
      {/* bunkers */}
      <ellipse cx="80" cy="200" rx="18" ry="10" fill="#D9C08A" opacity="0.65"/>
      <ellipse cx="265" cy="140" rx="14" ry="9" fill="#D9C08A" opacity="0.65"/>
      <ellipse cx="170" cy="55" rx="12" ry="8" fill="#D9C08A" opacity="0.65"/>
      {/* green */}
      <ellipse cx="140" cy="30" rx="42" ry="26" fill="url(#ph-grn)" stroke="#3D5A3B" strokeOpacity="0.45" strokeWidth="1"/>
      {/* pin */}
      <line x1="140" y1="22" x2="140" y2="6" stroke="#B8463A" strokeWidth="1.5"/>
      <path d="M 140 6 L 154 10 L 140 14 Z" fill="#B8463A"/>
      <circle cx="140" cy="22" r="2.5" fill="#B8463A"/>
      {/* tee */}
      <rect x="124" y="256" width="14" height="6" rx="1" fill="#3D5A3B" opacity="0.7"/>
      {/* ball position along the path */}
      <circle cx="205" cy="170" r="5.5" fill="#fff" stroke="#1A2218" strokeWidth="1.2"/>
      <circle cx="205" cy="170" r="12" fill="none" stroke="#1A2218" strokeOpacity="0.25" strokeWidth="0.8"/>
      {/* line ball→pin */}
      <line x1="205" y1="170" x2="140" y2="22" stroke="#B8463A" strokeOpacity="0.6" strokeWidth="1" strokeDasharray="3 3"/>
      {/* yardage markers along line */}
      <circle cx="172" cy="96" r="2" fill="#B8463A"/>
      <text x="178" y="100" fontSize="9" fill="#1A2218" fillOpacity="0.6" fontFamily="var(--mono)">142</text>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// 1) HOME — active round
// ─────────────────────────────────────────────────────────────
function Phone_Home({ onTab, onScore, onManual, onScorecard }) {
  const c = window.CURRENT;
  const hole = window.COURSES[0].holes[c.hole - 1];
  return (
    <div className="phone-screen grain">
      <PhoneStatus/>
      {/* Header */}
      <div style={{ padding: '4px 22px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <PhoneEyebrow>Live round</PhoneEyebrow>
          <div style={{ fontFamily: 'var(--serif)', fontSize: 22, lineHeight: 1.1, color: 'var(--ink)', marginTop: 2 }}>Arrowhead Glen</div>
        </div>
        <div style={{ width: 36, height: 36, borderRadius: 18, border: '1px solid var(--hairline)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--ink-soft)' }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.5"/><circle cx="12" cy="12" r="3" fill="currentColor"/></svg>
        </div>
      </div>

      {/* Hole header */}
      <div style={{ padding: '0 22px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
          <span style={{ fontFamily: 'var(--serif)', fontSize: 54, lineHeight: 1, color: 'var(--moss)' }}>{c.hole}</span>
          <span style={{ fontFamily: 'var(--mono)', fontSize: 12, color: 'var(--ink-mute)', letterSpacing: 1.4 }}>HOLE · PAR {hole.par}</span>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--ink-mute)', letterSpacing: 1.5 }}>HOLE LENGTH</div>
          <div className="tabular" style={{ fontFamily: 'var(--mono)', fontSize: 14, color: 'var(--ink)', marginTop: 2 }}>{hole.yards} yd</div>
        </div>
      </div>

      {/* Hero numbers */}
      <div style={{ padding: '20px 22px 0' }}>
        <div style={{ display: 'flex', alignItems: 'baseline' }}>
          <span className="tabular" style={{ fontFamily: 'var(--serif)', fontSize: 128, lineHeight: 0.85, color: 'var(--ink)', letterSpacing: -3 }}>{c.yardsToPin}</span>
          <div style={{ marginLeft: 12, display: 'flex', flexDirection: 'column' }}>
            <span style={{ fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--ink-mute)', letterSpacing: 1.6 }}>YARDS</span>
            <span style={{ fontFamily: 'var(--serif)', fontStyle: 'italic', fontSize: 18, color: 'var(--ink-soft)', marginTop: 4 }}>to&nbsp;pin</span>
          </div>
        </div>
        <div style={{ marginTop: 14, display: 'flex', gap: 8 }}>
          {[
            { k: 'Front', v: c.fcb[0] },
            { k: 'Center', v: c.fcb[1], strong: true },
            { k: 'Back', v: c.fcb[2] },
          ].map(x => (
            <div key={x.k} style={{ flex: 1, padding: '10px 12px', borderRadius: 12,
              background: x.strong ? 'var(--moss)' : 'var(--paper-2)',
              color: x.strong ? '#F2ECDD' : 'var(--ink)',
              display: 'flex', flexDirection: 'column' }}>
              <span style={{ fontFamily: 'var(--mono)', fontSize: 9, letterSpacing: 1.4,
                opacity: x.strong ? 0.7 : 1, color: x.strong ? '#F2ECDD' : 'var(--ink-mute)' }}>{x.k.toUpperCase()}</span>
              <span className="tabular" style={{ fontFamily: 'var(--mono)', fontSize: 20, fontWeight: 600, marginTop: 2 }}>{x.v}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Map */}
      <div style={{ marginTop: 16, marginLeft: 22, marginRight: 22, borderRadius: 16, overflow: 'hidden',
        background: '#E6DDC6', border: '1px solid var(--line)', position: 'relative' }}>
        <HoleMap height={220}/>
        <button onClick={onManual} style={{ position: 'absolute', top: 10, right: 10,
          padding: '6px 10px', borderRadius: 14, background: 'rgba(26,34,24,0.85)',
          color: '#F2ECDD', border: 'none', fontFamily: 'var(--sans)', fontSize: 11, fontWeight: 600,
          display: 'flex', alignItems: 'center', gap: 4 }}>
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none"><path d="M12 18V4M12 4L5 11M12 4L19 11" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/></svg>
          Set pin
        </button>
      </div>

      {/* Actions */}
      <div style={{ marginTop: 16, padding: '0 22px', display: 'flex', gap: 8 }}>
        <button onClick={onScore} style={{ flex: 1, height: 50, borderRadius: 25, border: 'none',
          background: 'var(--moss)', color: '#F2ECDD',
          fontFamily: 'var(--sans)', fontWeight: 600, fontSize: 15 }}>
          Record stroke
        </button>
        <button onClick={onScorecard} style={{ width: 50, height: 50, borderRadius: 25,
          background: 'var(--paper-2)', color: 'var(--ink)', border: '1px solid var(--line)',
          display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><rect x="4" y="3" width="16" height="18" rx="2" stroke="currentColor" strokeWidth="1.5"/><path d="M8 8H16M8 12H16M8 16H13" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/></svg>
        </button>
      </div>

      <div style={{ flex: 1 }}/>
      <PhoneTabs active="home" onChange={onTab}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2) COURSE CONFIRM — GPS detected sheet
// ─────────────────────────────────────────────────────────────
function Phone_CourseConfirm({ onCancel, onStart }) {
  return (
    <div className="phone-screen grain" style={{ background: 'var(--moss-deep)' }}>
      {/* Dark hero with course art */}
      <div style={{ position: 'relative', flex: 1, color: '#F2ECDD' }}>
        <svg viewBox="0 0 402 600" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
          <defs>
            <radialGradient id="dgrn" cx="50%" cy="65%" r="60%">
              <stop offset="0%" stopColor="#3D5A3B"/>
              <stop offset="100%" stopColor="#0E140F"/>
            </radialGradient>
          </defs>
          <rect width="402" height="600" fill="url(#dgrn)"/>
          {/* abstract hills */}
          <path d="M0 420 Q 100 380 200 410 T 402 405 V 600 H 0 Z" fill="#243B26"/>
          <path d="M0 470 Q 120 440 220 470 T 402 465 V 600 H 0 Z" fill="#1A2A1C"/>
          <path d="M0 520 Q 140 500 240 520 T 402 515 V 600 H 0 Z" fill="#0E140F"/>
          {/* sun */}
          <circle cx="290" cy="240" r="48" fill="#D9C08A" opacity="0.85"/>
        </svg>

        <div style={{ position: 'relative', padding: '60px 28px 0', color: '#F2ECDD' }}>
          <IOSStatusBar dark time="9:14"/>
          <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ width: 6, height: 6, borderRadius: 3, background: '#94B27E', boxShadow: '0 0 8px #94B27E' }}/>
            <span style={{ fontFamily: 'var(--mono)', fontSize: 11, letterSpacing: 2, color: '#94B27E' }}>LOCATION CONFIRMED</span>
          </div>
          <div style={{ marginTop: 30 }}>
            <div style={{ fontFamily: 'var(--serif)', fontSize: 52, lineHeight: 0.95, fontStyle: 'italic' }}>Arrowhead</div>
            <div style={{ fontFamily: 'var(--serif)', fontSize: 52, lineHeight: 0.95, marginTop: 2 }}>Glen</div>
          </div>
          <div style={{ marginTop: 14, fontFamily: 'var(--sans)', fontSize: 13, color: 'rgba(242,236,221,0.7)' }}>
            Sonoma, California · 18 holes · Par 72
          </div>

          <div style={{ marginTop: 28, padding: '12px 14px', borderRadius: 12,
            background: 'rgba(242,236,221,0.08)', backdropFilter: 'blur(6px)',
            border: '1px solid rgba(242,236,221,0.12)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontFamily: 'var(--mono)', fontSize: 9, color: 'rgba(242,236,221,0.5)', letterSpacing: 1.5 }}>YOUR LAST ROUND</div>
                <div className="tabular" style={{ fontFamily: 'var(--serif)', fontSize: 26, marginTop: 2 }}>84 <span style={{ color: '#94B27E', fontSize: 16 }}>+12</span></div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontFamily: 'var(--mono)', fontSize: 9, color: 'rgba(242,236,221,0.5)', letterSpacing: 1.5 }}>AVG · 7 ROUNDS</div>
                <div className="tabular" style={{ fontFamily: 'var(--serif)', fontSize: 26, marginTop: 2 }}>87.3</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom action sheet */}
      <div style={{ background: 'var(--paper)', borderTopLeftRadius: 24, borderTopRightRadius: 24,
        padding: '22px 22px 32px', color: 'var(--ink)' }}>
        <div style={{ width: 36, height: 4, borderRadius: 2, background: 'var(--line)', margin: '0 auto 18px' }}/>
        <div style={{ fontFamily: 'var(--serif)', fontSize: 22, lineHeight: 1.2 }}>Ready to play 18 holes?</div>
        <div style={{ fontFamily: 'var(--sans)', fontSize: 13, color: 'var(--ink-soft)', marginTop: 6 }}>
          Yardages and hole maps are loaded. Your watch will follow along automatically.
        </div>
        <button onClick={onStart} style={{ marginTop: 16, width: '100%', height: 52, borderRadius: 26, border: 'none',
          background: 'var(--moss)', color: '#F2ECDD', fontFamily: 'var(--sans)', fontWeight: 600, fontSize: 15 }}>
          Start round
        </button>
        <button onClick={onCancel} style={{ marginTop: 8, width: '100%', height: 40, borderRadius: 20, border: 'none',
          background: 'transparent', color: 'var(--ink-soft)', fontFamily: 'var(--sans)', fontSize: 13 }}>
          Choose a different course
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3) MANUAL INPUT — voice + wheel + compass
// ─────────────────────────────────────────────────────────────
function Phone_Manual({ onCancel, onConfirm }) {
  const [listening, setListening] = React.useState(true);
  const [yards, setYards] = React.useState(132);
  const [dir, setDir] = React.useState(355); // north-ish

  // Auto-finish "listening" after 1.6s to reveal parsed values
  React.useEffect(() => {
    if (!listening) return;
    const id = setTimeout(() => setListening(false), 1800);
    return () => clearTimeout(id);
  }, [listening]);

  // Wheel of values around current yardage
  const wheelVals = Array.from({ length: 9 }, (_, i) => yards - 4 + i);
  const compassPts = Array.from({ length: 36 });

  return (
    <div className="phone-screen grain">
      <PhoneStatus/>
      <div style={{ padding: '8px 22px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <button onClick={onCancel} style={{ background: 'none', border: 'none', color: 'var(--ink-soft)',
          fontFamily: 'var(--sans)', fontSize: 14 }}>Cancel</button>
        <PhoneEyebrow>Set distance</PhoneEyebrow>
        <button onClick={() => setListening(true)} style={{ background: 'none', border: 'none', color: 'var(--pin)',
          fontFamily: 'var(--sans)', fontSize: 14, fontWeight: 600 }}>Retry</button>
      </div>

      <div style={{ padding: '14px 22px 0' }}>
        <div style={{ fontFamily: 'var(--serif)', fontSize: 28, lineHeight: 1.1 }}>
          {listening ? 'Listening…' : 'Got it.'}
        </div>
        <div style={{ fontFamily: 'var(--serif)', fontStyle: 'italic', fontSize: 18, color: 'var(--ink-soft)', marginTop: 4 }}>
          Try "132 yards north" or "150 to the right."
        </div>
      </div>

      {/* Voice card */}
      <div style={{ margin: '18px 22px 0', padding: '16px 18px', borderRadius: 18,
        background: listening ? 'var(--moss-deep)' : 'var(--paper-2)',
        color: listening ? '#F2ECDD' : 'var(--ink)',
        border: listening ? 'none' : '1px solid var(--line)', position: 'relative' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ width: 8, height: 8, borderRadius: 4,
            background: listening ? '#E07A6D' : '#94B27E',
            animation: listening ? 'phpulse 1.4s ease-in-out infinite' : 'none' }}/>
          <span style={{ fontFamily: 'var(--mono)', fontSize: 10, letterSpacing: 1.6,
            color: listening ? '#E07A6D' : 'var(--ink-mute)' }}>
            {listening ? 'LISTENING' : 'TRANSCRIBED'}
          </span>
        </div>
        <style>{`@keyframes phpulse{0%,100%{opacity:1}50%{opacity:.3}}`}</style>

        {/* waveform / transcript */}
        <div style={{ marginTop: 10, height: 30, display: 'flex', alignItems: 'center', gap: 3 }}>
          {listening ?
            [14, 22, 10, 28, 18, 30, 14, 24, 16, 20, 12, 26, 14, 22, 10, 18, 26, 12, 20].map((h, i) => (
              <span key={i} style={{ width: 3, height: h, background: '#94B27E', opacity: 0.5 + (h / 70), borderRadius: 2,
                animation: `phwave 0.8s ease-in-out infinite ${i * 60}ms` }}/>
            )) :
            <span style={{ fontFamily: 'var(--serif)', fontStyle: 'italic', fontSize: 18, color: 'var(--ink)' }}>
              "{yards} yards, north"
            </span>
          }
          <style>{`@keyframes phwave{0%,100%{transform:scaleY(.6)}50%{transform:scaleY(1.4)}}`}</style>
        </div>
      </div>

      {/* Number wheel + compass — visible always; preset/adjustable */}
      <div style={{ marginTop: 18, padding: '0 22px', display: 'flex', gap: 12 }}>
        {/* Yards wheel */}
        <div style={{ flex: 1, padding: 14, borderRadius: 16, background: 'var(--paper-2)',
          border: '1px solid var(--line)' }}>
          <div style={{ fontFamily: 'var(--mono)', fontSize: 10, letterSpacing: 1.6, color: 'var(--ink-mute)' }}>YARDS</div>
          <div style={{ position: 'relative', height: 160, marginTop: 8 }}>
            <div style={{ position: 'absolute', left: 0, right: 0, top: '50%', height: 30, transform: 'translateY(-50%)',
              background: 'var(--paper)', borderRadius: 8, border: '1px solid var(--hairline)' }}/>
            <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', alignItems: 'center',
              gap: 6, fontFamily: 'var(--mono)', height: '100%', justifyContent: 'center' }}>
              {wheelVals.map((v, i) => {
                const d = Math.abs(i - 4);
                return (
                  <span key={v} className="tabular" style={{ fontSize: i === 4 ? 28 : 16,
                    fontWeight: i === 4 ? 600 : 400,
                    color: i === 4 ? 'var(--ink)' : 'var(--ink-mute)',
                    opacity: 1 - d * 0.22, lineHeight: 1 }}>{v}</span>
                );
              })}
            </div>
          </div>
        </div>

        {/* Compass */}
        <div style={{ flex: 1, padding: 14, borderRadius: 16, background: 'var(--paper-2)',
          border: '1px solid var(--line)' }}>
          <div style={{ fontFamily: 'var(--mono)', fontSize: 10, letterSpacing: 1.6, color: 'var(--ink-mute)' }}>BEARING</div>
          <div style={{ position: 'relative', height: 160, marginTop: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg viewBox="-80 -80 160 160" style={{ width: 130, height: 130 }}>
              <circle r="76" fill="none" stroke="var(--line)" strokeWidth="1"/>
              {compassPts.map((_, i) => {
                const a = (i / 36) * Math.PI * 2 - Math.PI / 2;
                const inner = i % 9 === 0 ? 64 : 70;
                return <line key={i} x1={Math.cos(a) * inner} y1={Math.sin(a) * inner}
                  x2={Math.cos(a) * 74} y2={Math.sin(a) * 74}
                  stroke={i % 9 === 0 ? 'var(--ink)' : 'var(--hairline)'} strokeWidth={i % 9 === 0 ? 1.2 : 0.7}/>;
              })}
              {['N', 'E', 'S', 'W'].map((l, i) => {
                const a = (i / 4) * Math.PI * 2 - Math.PI / 2;
                return <text key={l} x={Math.cos(a) * 56} y={Math.sin(a) * 56 + 4}
                  textAnchor="middle" fontFamily="var(--sans)" fontWeight="600" fontSize="11"
                  fill={l === 'N' ? '#B8463A' : 'var(--ink-soft)'}>{l}</text>;
              })}
              {/* arrow */}
              <g transform={`rotate(${dir})`}>
                <line x1="0" y1="0" x2="0" y2="-58" stroke="#B8463A" strokeWidth="2" strokeLinecap="round"/>
                <path d="M 0 -64 L 5 -54 L -5 -54 Z" fill="#B8463A"/>
              </g>
              <circle r="3" fill="var(--ink)"/>
            </svg>
          </div>
        </div>
      </div>

      <div style={{ padding: '14px 22px 0', fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--ink-mute)', letterSpacing: 1.2 }}>
        {listening ? '· · · ' : `${yards} YD · ${dir}° (N)`}
      </div>

      <div style={{ flex: 1 }}/>

      <div style={{ padding: '0 22px 16px' }}>
        <button onClick={onConfirm} disabled={listening} style={{ width: '100%', height: 52, borderRadius: 26, border: 'none',
          background: listening ? 'var(--paper-2)' : 'var(--moss)',
          color: listening ? 'var(--ink-mute)' : '#F2ECDD',
          fontFamily: 'var(--sans)', fontWeight: 600, fontSize: 15,
          transition: 'background .2s' }}>
          Set pin
        </button>
      </div>
      <PhoneTabs active="home" onChange={() => {}}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 4) SCORECARD — current round full table
// ─────────────────────────────────────────────────────────────
function Phone_Scorecard({ onBack, onTab }) {
  const front = [
    { h: 1, par: 4, s: 5, p: 2 },
    { h: 2, par: 3, s: 3, p: 1 },
    { h: 3, par: 5, s: 6, p: 2 },
    { h: 4, par: 4, s: null, p: null, current: true },
    { h: 5, par: 4, s: null, p: null },
    { h: 6, par: 3, s: null, p: null },
    { h: 7, par: 5, s: null, p: null },
    { h: 8, par: 4, s: null, p: null },
    { h: 9, par: 4, s: null, p: null },
  ];
  const cell = (s, par) => {
    if (s == null) return <span style={{ color: 'var(--ink-mute)' }}>—</span>;
    const d = s - par;
    const ring = d <= -1;
    const sq = d >= 1;
    return (
      <span className="tabular" style={{
        fontFamily: 'var(--mono)', fontWeight: 600,
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        width: 26, height: 26,
        ...(ring ? { borderRadius: 13, border: `1.5px solid var(--moss)`, color: 'var(--moss)' } :
            sq ? { border: `1.5px solid var(--pin)`, color: 'var(--pin)' } :
            { color: 'var(--ink)' }),
      }}>{s}</span>
    );
  };
  return (
    <div className="phone-screen grain">
      <PhoneStatus/>
      <div style={{ padding: '4px 22px 12px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <button onClick={onBack} style={{ background: 'none', border: 'none', color: 'var(--ink-soft)', padding: 0 }}>
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M15 19L8 12L15 5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"/></svg>
        </button>
        <div>
          <PhoneEyebrow>Scorecard</PhoneEyebrow>
          <div style={{ fontFamily: 'var(--serif)', fontSize: 22, lineHeight: 1 }}>Arrowhead · Today</div>
        </div>
      </div>

      <div style={{ margin: '8px 22px 0', padding: '14px', borderRadius: 16,
        background: 'var(--moss-deep)', color: '#F2ECDD' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <div>
            <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'rgba(242,236,221,0.6)', letterSpacing: 1.6 }}>THRU 3 · PAR 12</div>
            <div className="tabular" style={{ fontFamily: 'var(--serif)', fontSize: 38, lineHeight: 1 }}>14 <span style={{ color: '#E07A6D', fontSize: 22 }}>+2</span></div>
          </div>
          <div style={{ display: 'flex', gap: 14, fontFamily: 'var(--mono)', fontSize: 12 }}>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 9, opacity: 0.6, letterSpacing: 1.4 }}>PUTTS</div>
              <div className="tabular" style={{ fontSize: 18, marginTop: 2 }}>5</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 9, opacity: 0.6, letterSpacing: 1.4 }}>AVG/HOLE</div>
              <div className="tabular" style={{ fontSize: 18, marginTop: 2 }}>4.7</div>
            </div>
          </div>
        </div>
      </div>

      {/* Table */}
      <div style={{ margin: '14px 22px 0', borderRadius: 16, background: 'var(--paper-2)', overflow: 'hidden',
        border: '1px solid var(--line)' }}>
        <div style={{ display: 'grid', gridTemplateColumns: '40px 50px 1fr 60px 50px',
          padding: '10px 14px', fontFamily: 'var(--mono)', fontSize: 9, letterSpacing: 1.4,
          color: 'var(--ink-mute)', borderBottom: '1px solid var(--line)' }}>
          <span>HOLE</span><span>PAR</span><span>YD</span><span style={{ textAlign: 'center' }}>SCORE</span><span style={{ textAlign: 'right' }}>PUTTS</span>
        </div>
        {front.map(h => {
          const hole = window.COURSES[0].holes[h.h - 1];
          return (
            <div key={h.h} style={{ display: 'grid', gridTemplateColumns: '40px 50px 1fr 60px 50px',
              padding: '8px 14px', alignItems: 'center', fontFamily: 'var(--mono)', fontSize: 13,
              background: h.current ? 'rgba(107,142,90,0.12)' : 'transparent',
              borderBottom: h.h === 9 ? 'none' : '1px solid var(--line-soft)' }}>
              <span style={{ fontFamily: 'var(--serif)', fontSize: 18, color: h.current ? 'var(--moss)' : 'var(--ink)' }}>{h.h}</span>
              <span className="tabular" style={{ color: 'var(--ink-soft)' }}>{h.par}</span>
              <span className="tabular" style={{ color: 'var(--ink-mute)', fontSize: 11 }}>{hole.yards}</span>
              <span style={{ textAlign: 'center' }}>{h.current ? <span style={{ fontSize: 10, color: 'var(--moss)', fontWeight: 600 }}>· NOW ·</span> : cell(h.s, h.par)}</span>
              <span className="tabular" style={{ textAlign: 'right', color: 'var(--ink-soft)' }}>{h.p ?? '—'}</span>
            </div>
          );
        })}
      </div>

      <div style={{ flex: 1 }}/>
      <PhoneTabs active="home" onChange={onTab}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 5) HISTORY LIST
// ─────────────────────────────────────────────────────────────
function Phone_History({ onTab, onOpenStats }) {
  const rounds = window.HISTORY;
  return (
    <div className="phone-screen grain">
      <PhoneStatus/>
      <div style={{ padding: '4px 22px 6px' }}>
        <PhoneEyebrow>Rounds</PhoneEyebrow>
        <div style={{ fontFamily: 'var(--serif)', fontSize: 32, lineHeight: 1.1, marginTop: 2 }}>Your history</div>
      </div>
      {/* Toggle */}
      <div style={{ padding: '10px 22px 0', display: 'flex', gap: 4 }}>
        <button style={{ flex: 1, padding: '8px 0', borderRadius: 18, border: 'none',
          background: 'var(--ink)', color: 'var(--paper)',
          fontFamily: 'var(--sans)', fontSize: 12, fontWeight: 600 }}>Rounds</button>
        <button onClick={onOpenStats} style={{ flex: 1, padding: '8px 0', borderRadius: 18, border: 'none',
          background: 'var(--paper-2)', color: 'var(--ink-soft)',
          fontFamily: 'var(--sans)', fontSize: 12, fontWeight: 500 }}>Stats</button>
      </div>

      {/* Summary strip */}
      <div style={{ margin: '14px 22px 0', padding: '14px 16px', borderRadius: 16,
        background: 'var(--paper-2)', border: '1px solid var(--line)',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div style={{ fontFamily: 'var(--mono)', fontSize: 10, letterSpacing: 1.6, color: 'var(--ink-mute)' }}>LAST 8 ROUNDS</div>
          <div style={{ fontFamily: 'var(--serif)', fontSize: 22, marginTop: 2 }}>Trending <span style={{ fontStyle: 'italic', color: 'var(--moss)' }}>down</span></div>
        </div>
        {/* sparkline */}
        <svg width="100" height="36" viewBox="0 0 100 36">
          <polyline points="0,8 14,4 28,16 42,12 56,18 70,24 84,20 100,28"
            fill="none" stroke="var(--moss)" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
          <circle cx="100" cy="28" r="2.5" fill="var(--moss)"/>
        </svg>
      </div>

      {/* List */}
      <div style={{ flex: 1, overflow: 'hidden', padding: '14px 22px 0', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {rounds.slice(0, 6).map(r => {
          const delta = r.score - r.par;
          return (
            <div key={r.id} style={{ display: 'flex', alignItems: 'center', gap: 12,
              padding: '12px 14px', borderRadius: 14,
              background: 'var(--paper-2)', border: '1px solid var(--line)' }}>
              <div style={{ width: 44, textAlign: 'center' }}>
                <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--ink-mute)' }}>{r.date.split(' ')[0]}</div>
                <div style={{ fontFamily: 'var(--serif)', fontSize: 22, lineHeight: 1, marginTop: 2 }}>{r.date.split(' ')[1]}</div>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: 'var(--sans)', fontSize: 13, fontWeight: 600, color: 'var(--ink)' }}>{r.course}</div>
                <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--ink-mute)', marginTop: 2, letterSpacing: 1 }}>
                  {r.fwy}/14 FWY · {r.gir}/18 GIR · {r.putts} PUTTS
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div className="tabular" style={{ fontFamily: 'var(--serif)', fontSize: 26, lineHeight: 1 }}>{r.score}</div>
                <div className="tabular" style={{ fontFamily: 'var(--mono)', fontSize: 11,
                  color: delta > 12 ? 'var(--pin)' : delta > 8 ? 'var(--sand-deep)' : 'var(--moss)', marginTop: 1 }}>+{delta}</div>
              </div>
            </div>
          );
        })}
      </div>

      <PhoneTabs active="history" onChange={onTab}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 6) STATS DASHBOARD
// ─────────────────────────────────────────────────────────────
function Phone_Stats({ onTab, onOpenList }) {
  const scores = [90, 92, 87, 89, 86, 91, 88, 84];
  const min = 82, max = 94;
  const points = scores.map((s, i) => {
    const x = (i / (scores.length - 1)) * 280 + 20;
    const y = 130 - ((s - min) / (max - min)) * 100;
    return { x, y, s };
  });
  const pathD = points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ');
  return (
    <div className="phone-screen grain">
      <PhoneStatus/>
      <div style={{ padding: '4px 22px 6px' }}>
        <PhoneEyebrow>Stats</PhoneEyebrow>
        <div style={{ fontFamily: 'var(--serif)', fontSize: 32, lineHeight: 1.1, marginTop: 2 }}>Eight rounds in</div>
      </div>
      <div style={{ padding: '10px 22px 0', display: 'flex', gap: 4 }}>
        <button onClick={onOpenList} style={{ flex: 1, padding: '8px 0', borderRadius: 18, border: 'none',
          background: 'var(--paper-2)', color: 'var(--ink-soft)',
          fontFamily: 'var(--sans)', fontSize: 12, fontWeight: 500 }}>Rounds</button>
        <button style={{ flex: 1, padding: '8px 0', borderRadius: 18, border: 'none',
          background: 'var(--ink)', color: 'var(--paper)',
          fontFamily: 'var(--sans)', fontSize: 12, fontWeight: 600 }}>Stats</button>
      </div>

      {/* Top KPI strip */}
      <div style={{ margin: '14px 22px 0', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
        {[
          { k: 'AVG', v: '87.3', sub: '↓ 2.4' },
          { k: 'BEST', v: '84', sub: 'May 12' },
          { k: 'HCP', v: '14.6', sub: 'idx' },
        ].map(x => (
          <div key={x.k} style={{ padding: '12px', borderRadius: 14, background: 'var(--paper-2)',
            border: '1px solid var(--line)' }}>
            <div style={{ fontFamily: 'var(--mono)', fontSize: 9, letterSpacing: 1.6, color: 'var(--ink-mute)' }}>{x.k}</div>
            <div className="tabular" style={{ fontFamily: 'var(--serif)', fontSize: 28, marginTop: 2, lineHeight: 1 }}>{x.v}</div>
            <div style={{ fontFamily: 'var(--mono)', fontSize: 10, marginTop: 4, color: 'var(--moss)' }}>{x.sub}</div>
          </div>
        ))}
      </div>

      {/* Score trend chart */}
      <div style={{ margin: '14px 22px 0', padding: '16px', borderRadius: 16,
        background: 'var(--paper-2)', border: '1px solid var(--line)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--ink-mute)', letterSpacing: 1.6 }}>SCORE TREND</div>
          <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--ink-mute)' }}>8 ROUNDS</div>
        </div>
        <svg viewBox="0 0 320 150" style={{ width: '100%', height: 150, marginTop: 4 }}>
          {/* baseline */}
          <line x1="20" y1="130" x2="300" y2="130" stroke="var(--line)" strokeWidth="0.5"/>
          {[88, 92].map(v => (
            <line key={v} x1="20" x2="300" y1={130 - ((v - min) / (max - min)) * 100} y2={130 - ((v - min) / (max - min)) * 100}
              stroke="var(--line-soft)" strokeWidth="0.5" strokeDasharray="3 3"/>
          ))}
          {/* trend line */}
          <path d={pathD} fill="none" stroke="var(--moss)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
          {points.map((p, i) => (
            <g key={i}>
              <circle cx={p.x} cy={p.y} r={i === points.length - 1 ? 4 : 2.5} fill="var(--paper-2)" stroke="var(--moss)" strokeWidth="1.5"/>
              {i === points.length - 1 && (
                <text x={p.x} y={p.y - 10} textAnchor="middle" fontSize="11" fontFamily="var(--mono)" fontWeight="600" fill="var(--moss)">{p.s}</text>
              )}
            </g>
          ))}
        </svg>
      </div>

      {/* Distribution: par / birdie / bogey */}
      <div style={{ margin: '14px 22px 0', padding: '16px', borderRadius: 16,
        background: 'var(--paper-2)', border: '1px solid var(--line)' }}>
        <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--ink-mute)', letterSpacing: 1.6 }}>HOLE OUTCOMES · ALL TIME</div>
        <div style={{ marginTop: 10, display: 'flex', height: 28, borderRadius: 6, overflow: 'hidden' }}>
          {[
            { k: 'Eagle/Birdie', pct: 6, c: 'var(--fairway-2)' },
            { k: 'Par', pct: 34, c: 'var(--moss)' },
            { k: 'Bogey', pct: 38, c: 'var(--sand)' },
            { k: 'Double+', pct: 22, c: 'var(--pin)' },
          ].map(x => (
            <div key={x.k} style={{ width: `${x.pct}%`, background: x.c }} title={x.k}/>
          ))}
        </div>
        <div style={{ marginTop: 10, display: 'flex', justifyContent: 'space-between', fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--ink-soft)' }}>
          <span>BIRD 6%</span><span>PAR 34%</span><span>BGY 38%</span><span>DBL+ 22%</span>
        </div>
      </div>

      <div style={{ flex: 1 }}/>
      <PhoneTabs active="stats" onChange={onTab}/>
    </div>
  );
}

Object.assign(window, {
  Phone_Home, Phone_CourseConfirm, Phone_Manual, Phone_Scorecard, Phone_History, Phone_Stats, HoleMap, PhoneTabs,
});
