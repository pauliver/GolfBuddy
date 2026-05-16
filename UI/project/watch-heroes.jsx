// Watch hero screens — six variations of the main yardage display.
// All render inside a 205×251 watch screen. Share the same data shape:
//   { hole, par, yards, fcb: [front, center, back], pinDir }

const HERO_INK = '#F2ECDD';
const HERO_DIM = 'rgba(242,236,221,0.5)';
const HERO_FAINT = 'rgba(242,236,221,0.22)';
const HERO_FAIRWAY = '#6B8E5A';
const HERO_FAIRWAY_2 = '#94B27E';
const HERO_PIN = '#E07A6D';
const HERO_SAND = '#D9C08A';

// ─────────────────────────────────────────────────────────────
// 1) Apple HIG — system style
// ─────────────────────────────────────────────────────────────
function Hero_HIG({ hole, par, yards, fcb }) {
  return (
    <div style={{ position: 'absolute', inset: 0, padding: '26px 16px 14px',
      display: 'flex', flexDirection: 'column', color: HERO_INK,
      fontFamily: '-apple-system, "SF Pro Rounded", "SF Pro", system-ui' }}>
      {/* Top hole pill */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 13, fontWeight: 600 }}>
        <span style={{ color: HERO_FAIRWAY_2 }}>Hole {hole}</span>
        <span style={{ color: HERO_DIM }}>Par {par}</span>
      </div>
      {/* Big number */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
        <div className="tabular" style={{ fontSize: 88, fontWeight: 600, lineHeight: 0.9, letterSpacing: -3 }}>{yards}</div>
        <div style={{ fontSize: 11, color: HERO_DIM, textTransform: 'uppercase', letterSpacing: 1.4, marginTop: 6, fontWeight: 600 }}>yards to pin</div>
      </div>
      {/* F/B row */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', fontSize: 14 }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start' }}>
          <span style={{ fontSize: 10, color: HERO_DIM, letterSpacing: 1, textTransform: 'uppercase' }}>Front</span>
          <span className="tabular" style={{ fontWeight: 600, fontSize: 22, lineHeight: 1, marginTop: 2 }}>{fcb[0]}</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
          <span style={{ fontSize: 10, color: HERO_DIM, letterSpacing: 1, textTransform: 'uppercase' }}>Back</span>
          <span className="tabular" style={{ fontWeight: 600, fontSize: 22, lineHeight: 1, marginTop: 2 }}>{fcb[2]}</span>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 2) Bold Numerals — sport / typographic
// ─────────────────────────────────────────────────────────────
function Hero_Bold({ hole, par, yards, fcb }) {
  return (
    <div style={{ position: 'absolute', inset: 0, padding: '26px 14px 14px',
      background: 'radial-gradient(ellipse at 50% 60%, #0d1a10 0%, #000 80%)',
      color: HERO_INK, display: 'flex', flexDirection: 'column', fontFamily: 'var(--sans)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontFamily: 'var(--mono)',
        fontSize: 10, color: HERO_DIM, letterSpacing: 1.5, textTransform: 'uppercase' }}>
        <span>H{String(hole).padStart(2,'0')}</span>
        <span>PAR {par}</span>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', position: 'relative' }}>
        <div style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%) rotate(-90deg)',
          transformOrigin: 'left center', fontFamily: 'var(--mono)', fontSize: 9, letterSpacing: 3,
          color: HERO_FAIRWAY, textTransform: 'uppercase' }}>TO PIN</div>
        <div className="tabular" style={{ fontFamily: 'var(--mono)', fontSize: 102, fontWeight: 500, lineHeight: 0.85, letterSpacing: -5, color: HERO_INK }}>
          {yards}
        </div>
        <div style={{ fontFamily: 'var(--mono)', fontSize: 9, color: HERO_DIM, letterSpacing: 2, marginTop: 8 }}>YARDS · CENTER</div>
      </div>
      <div style={{ display: 'flex', gap: 6, fontFamily: 'var(--mono)', fontSize: 12 }}>
        <div style={{ flex: 1, padding: '6px 8px', border: '1px solid rgba(148,178,128,0.3)', borderRadius: 6,
          display: 'flex', justifyContent: 'space-between', color: HERO_FAIRWAY_2 }}>
          <span style={{ fontSize: 9, opacity: 0.7 }}>F</span><span className="tabular">{fcb[0]}</span>
        </div>
        <div style={{ flex: 1, padding: '6px 8px', border: '1px solid rgba(148,178,128,0.3)', borderRadius: 6,
          display: 'flex', justifyContent: 'space-between', color: HERO_FAIRWAY_2 }}>
          <span style={{ fontSize: 9, opacity: 0.7 }}>B</span><span className="tabular">{fcb[2]}</span>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3) Topographic Green — drawn green silhouette with arcs
// ─────────────────────────────────────────────────────────────
function Hero_Topo({ hole, par, yards, fcb }) {
  return (
    <div style={{ position: 'absolute', inset: 0, color: HERO_INK, fontFamily: 'var(--sans)' }}>
      {/* Top label */}
      <div style={{ position: 'absolute', top: 26, left: 0, right: 0, textAlign: 'center', zIndex: 2 }}>
        <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: HERO_FAIRWAY_2, letterSpacing: 2, textTransform: 'uppercase' }}>
          Hole {hole} · Par {par}
        </div>
      </div>
      {/* Big yards */}
      <div style={{ position: 'absolute', top: 50, left: 0, right: 0, textAlign: 'center', zIndex: 2 }}>
        <div className="tabular" style={{ fontFamily: 'var(--sans)', fontSize: 70, fontWeight: 600,
          lineHeight: 0.9, color: HERO_INK, letterSpacing: -2 }}>{yards}</div>
        <div style={{ fontFamily: 'var(--mono)', fontSize: 9, color: HERO_DIM, letterSpacing: 1.8, marginTop: 2 }}>YARDS</div>
      </div>
      {/* SVG topo green — fills bottom 55% */}
      <svg viewBox="0 0 205 140" style={{ position: 'absolute', bottom: 0, left: 0, width: '100%', height: 140 }}>
        <defs>
          <radialGradient id="greenGrad" cx="50%" cy="60%" r="60%">
            <stop offset="0%" stopColor="#6B8E5A" stopOpacity="0.55"/>
            <stop offset="100%" stopColor="#6B8E5A" stopOpacity="0.05"/>
          </radialGradient>
        </defs>
        {/* Concentric topo lines around pin */}
        {[18, 30, 44, 58, 72].map((r, i) => (
          <ellipse key={i} cx="102" cy="92" rx={r * 1.6} ry={r * 0.85}
            fill={i === 1 ? 'url(#greenGrad)' : 'none'}
            stroke={HERO_FAIRWAY} strokeOpacity={0.35 - i * 0.05} strokeWidth="0.7"/>
        ))}
        {/* Pin */}
        <line x1="102" y1="92" x2="102" y2="68" stroke={HERO_PIN} strokeWidth="1.2"/>
        <path d="M 102 68 L 116 72 L 102 76 Z" fill={HERO_PIN}/>
        <circle cx="102" cy="92" r="2.5" fill={HERO_PIN}/>
        {/* F/B labels on arcs */}
        <text x="10" y="113" fill={HERO_DIM} fontSize="10" fontFamily="var(--mono)" letterSpacing="1.5">F</text>
        <text x="10" y="138" fill={HERO_FAIRWAY_2} fontSize="32" fontWeight="600" fontFamily="var(--sans)" letterSpacing="-1.5" style={{ fontVariantNumeric: 'tabular-nums' }}>{fcb[0]}</text>
        <text x="195" y="113" fill={HERO_DIM} fontSize="10" fontFamily="var(--mono)" letterSpacing="1.5" textAnchor="end">B</text>
        <text x="195" y="138" fill={HERO_FAIRWAY_2} fontSize="32" fontWeight="600" fontFamily="var(--sans)" letterSpacing="-1.5" textAnchor="end" style={{ fontVariantNumeric: 'tabular-nums' }}>{fcb[2]}</text>
      </svg>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 4) Compass Pin — directional ring with arrow
// ─────────────────────────────────────────────────────────────
function Hero_Compass({ hole, par, yards, fcb, pinDir = 28 }) {
  const cx = 102, cy = 130, r = 80;
  // 32 tick marks
  const ticks = Array.from({ length: 32 }).map((_, i) => {
    const a = (i / 32) * Math.PI * 2 - Math.PI / 2;
    const inner = i % 8 === 0 ? r - 12 : r - 6;
    const outer = r - 2;
    return (
      <line key={i}
        x1={cx + Math.cos(a) * inner} y1={cy + Math.sin(a) * inner}
        x2={cx + Math.cos(a) * outer} y2={cy + Math.sin(a) * outer}
        stroke={i % 8 === 0 ? HERO_INK : HERO_FAINT}
        strokeWidth={i % 8 === 0 ? 1.4 : 0.8}/>
    );
  });
  const arrowA = (pinDir / 360) * Math.PI * 2 - Math.PI / 2;
  const ax = cx + Math.cos(arrowA) * (r - 18);
  const ay = cy + Math.sin(arrowA) * (r - 18);
  return (
    <div style={{ position: 'absolute', inset: 0, color: HERO_INK, fontFamily: 'var(--sans)' }}>
      <div style={{ position: 'absolute', top: 24, left: 0, right: 0, textAlign: 'center' }}>
        <div style={{ fontSize: 12, fontWeight: 600, color: HERO_FAIRWAY_2, letterSpacing: 0.3 }}>Hole {hole} · Par {par}</div>
      </div>
      <svg viewBox="0 0 205 251" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
        {ticks}
        {/* N label */}
        <text x={cx} y={cy - r + 4} fill={HERO_INK} fontSize="11" fontWeight="600" textAnchor="middle" fontFamily="var(--sans)">N</text>
        {/* Pin direction arrow */}
        <line x1={cx} y1={cy} x2={ax} y2={ay} stroke={HERO_PIN} strokeWidth="2" strokeLinecap="round"/>
        <circle cx={ax} cy={ay} r="3.5" fill={HERO_PIN}/>
        {/* Pin dot at end + flag */}
        <path d={`M ${ax} ${ay} l 8 -2 l -2 6 z`} fill={HERO_PIN}/>
        {/* Center yards */}
        <text x={cx} y={cy - 2} textAnchor="middle" fill={HERO_INK}
          fontSize="48" fontWeight="600" fontFamily="var(--sans)" letterSpacing="-2"
          style={{ fontVariantNumeric: 'tabular-nums' }}>{yards}</text>
        <text x={cx} y={cy + 16} textAnchor="middle" fill={HERO_DIM}
          fontSize="9" fontFamily="var(--mono)" letterSpacing="2">YARDS</text>
      </svg>
      <div style={{ position: 'absolute', bottom: 16, left: 0, right: 0, display: 'flex', justifyContent: 'space-between', padding: '0 18px',
        fontFamily: 'var(--mono)', fontSize: 11, color: HERO_FAIRWAY_2 }}>
        <span><span style={{ opacity: 0.6, marginRight: 4 }}>F</span><span className="tabular">{fcb[0]}</span></span>
        <span className="tabular" style={{ color: HERO_DIM, fontSize: 10 }}>{pinDir}°</span>
        <span><span style={{ opacity: 0.6, marginRight: 4 }}>B</span><span className="tabular">{fcb[2]}</span></span>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 5) Editorial Serif — calm, magazine
// ─────────────────────────────────────────────────────────────
function Hero_Serif({ hole, par, yards, fcb }) {
  const roman = ['','I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII','XIII','XIV','XV','XVI','XVII','XVIII'][hole] || hole;
  return (
    <div style={{ position: 'absolute', inset: 0, padding: '28px 18px 16px',
      background: 'linear-gradient(180deg, #0a120c 0%, #000 100%)',
      color: HERO_INK, display: 'flex', flexDirection: 'column', fontFamily: 'var(--serif)' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontFamily: 'var(--mono)', fontSize: 9, color: HERO_FAIRWAY_2, letterSpacing: 2, textTransform: 'uppercase' }}>Arrowhead</span>
        <span style={{ fontFamily: 'var(--mono)', fontSize: 9, color: HERO_DIM, letterSpacing: 2 }}>PAR {par}</span>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
        <div style={{ fontFamily: 'var(--serif)', fontStyle: 'italic', fontSize: 28, color: HERO_FAIRWAY_2, lineHeight: 1, marginBottom: -8 }}>hole</div>
        <div style={{ fontFamily: 'var(--serif)', fontSize: 36, color: HERO_INK, lineHeight: 1, marginLeft: 60 }}>{roman}</div>
        <div className="tabular" style={{ fontFamily: 'var(--serif)', fontSize: 110, lineHeight: 0.9, color: HERO_INK, letterSpacing: -3, marginTop: 6 }}>{yards}</div>
        <div style={{ fontFamily: 'var(--serif)', fontStyle: 'italic', fontSize: 16, color: HERO_DIM, marginTop: 2 }}>yards to the pin</div>
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontFamily: 'var(--mono)', fontSize: 11,
        borderTop: `1px solid ${HERO_FAINT}`, paddingTop: 8, color: HERO_FAIRWAY_2 }}>
        <span className="tabular">F · {fcb[0]}</span>
        <span className="tabular">B · {fcb[2]}</span>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 6) Living Map — top-down hole with ball/pin path
// ─────────────────────────────────────────────────────────────
function Hero_Map({ hole, par, yards, fcb }) {
  return (
    <div style={{ position: 'absolute', inset: 0, color: HERO_INK, fontFamily: 'var(--sans)',
      background: 'radial-gradient(ellipse at 50% 30%, #102218 0%, #000 75%)' }}>
      <div style={{ position: 'absolute', top: 26, left: 0, right: 0, textAlign: 'center', zIndex: 2 }}>
        <span style={{ fontSize: 11, fontWeight: 600, color: HERO_FAIRWAY_2, letterSpacing: 0.5 }}>Hole {hole}</span>
        <span style={{ fontSize: 11, color: HERO_DIM, marginLeft: 8 }}>Par {par}</span>
      </div>

      <svg viewBox="0 0 205 251" style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}>
        <defs>
          <radialGradient id="grnA" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor={HERO_FAIRWAY} stopOpacity="0.5"/>
            <stop offset="100%" stopColor={HERO_FAIRWAY} stopOpacity="0.1"/>
          </radialGradient>
        </defs>
        {/* Fairway path (curving from bottom tee to top green) */}
        <path d="M 80 245 C 60 200, 130 180, 130 140 C 130 110, 90 100, 90 70"
          fill="none" stroke={HERO_FAIRWAY} strokeOpacity="0.18" strokeWidth="42" strokeLinecap="round"/>
        <path d="M 80 245 C 60 200, 130 180, 130 140 C 130 110, 90 100, 90 70"
          fill="none" stroke={HERO_FAIRWAY} strokeOpacity="0.32" strokeWidth="34" strokeLinecap="round"/>
        {/* Sand bunker */}
        <ellipse cx="55" cy="180" rx="12" ry="8" fill={HERO_SAND} opacity="0.5"/>
        <ellipse cx="155" cy="115" rx="10" ry="7" fill={HERO_SAND} opacity="0.5"/>
        {/* Green at top */}
        <ellipse cx="90" cy="65" rx="32" ry="22" fill="url(#grnA)" stroke={HERO_FAIRWAY_2} strokeOpacity="0.5" strokeWidth="1"/>
        {/* Pin */}
        <line x1="90" y1="60" x2="90" y2="46" stroke={HERO_PIN} strokeWidth="1.2"/>
        <path d="M 90 46 L 100 49 L 90 52 Z" fill={HERO_PIN}/>
        <circle cx="90" cy="60" r="2" fill={HERO_PIN}/>
        {/* Ball position (mid-fairway) */}
        <circle cx="115" cy="158" r="4.5" fill={HERO_INK} stroke="#000" strokeWidth="1.5"/>
        <circle cx="115" cy="158" r="9" fill="none" stroke={HERO_INK} strokeOpacity="0.4" strokeWidth="0.6"/>
        {/* Yardage line ball→pin */}
        <line x1="115" y1="158" x2="90" y2="60" stroke={HERO_PIN} strokeOpacity="0.6" strokeWidth="0.8" strokeDasharray="2 2"/>
      </svg>

      {/* Yardage card overlay bottom */}
      <div style={{ position: 'absolute', bottom: 12, left: 12, right: 12,
        background: 'rgba(10,18,12,0.7)', backdropFilter: 'blur(8px)',
        border: `1px solid ${HERO_FAINT}`, borderRadius: 10, padding: '8px 12px',
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
        <div>
          <span className="tabular" style={{ fontSize: 36, fontWeight: 600, color: HERO_INK, letterSpacing: -1.5 }}>{yards}</span>
          <span style={{ fontSize: 10, color: HERO_DIM, marginLeft: 4, letterSpacing: 1.2 }}>YD</span>
        </div>
        <div style={{ display: 'flex', gap: 10, fontFamily: 'var(--mono)', fontSize: 10, color: HERO_FAIRWAY_2 }}>
          <span><span style={{ opacity: 0.6 }}>F </span><span className="tabular">{fcb[0]}</span></span>
          <span><span style={{ opacity: 0.6 }}>B </span><span className="tabular">{fcb[2]}</span></span>
        </div>
      </div>
    </div>
  );
}

const HEROES = {
  hig:     { name: 'Apple HIG',       component: Hero_HIG },
  bold:    { name: 'Bold Numerals',   component: Hero_Bold },
  topo:    { name: 'Topo Green',      component: Hero_Topo },
  compass: { name: 'Compass',         component: Hero_Compass },
  serif:   { name: 'Editorial Serif', component: Hero_Serif },
  map:     { name: 'Living Map',      component: Hero_Map },
};

Object.assign(window, { Hero_HIG, Hero_Bold, Hero_Topo, Hero_Compass, Hero_Serif, Hero_Map, HEROES });
