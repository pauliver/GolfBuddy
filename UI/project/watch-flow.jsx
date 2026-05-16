// Watch flow screens — surrounding the hero.
//   • CourseConfirm — "Playing Arrowhead?" on tee
//   • ScoreInput — record strokes + putts after holing out
//   • HoleAdvance — between-hole celebration / advance prompt
//   • VoiceInput — manual yardage via voice ("132 yards north")
//   • Scorecard — quick scrollable summary

const WF_INK = '#F2ECDD';
const WF_DIM = 'rgba(242,236,221,0.55)';
const WF_FAINT = 'rgba(242,236,221,0.18)';
const WF_FAIRWAY_2 = '#94B27E';
const WF_PIN = '#E07A6D';
const WF_SAND = '#D9C08A';

// ─────────────────────────────────────────────────────────────
// Course confirm — GPS detected, tap to begin
// ─────────────────────────────────────────────────────────────
function Watch_CourseConfirm({ course = 'Arrowhead Glen', subtitle = 'Sonoma · 18 holes' }) {
  return (
    <div style={{ position: 'absolute', inset: 0, padding: '30px 16px 14px',
      color: WF_INK, fontFamily: 'var(--sans)', display: 'flex', flexDirection: 'column' }}>
      <div style={{ fontFamily: 'var(--mono)', fontSize: 9, color: WF_FAIRWAY_2, letterSpacing: 2, textTransform: 'uppercase' }}>
        ◌ Near you
      </div>
      <div style={{ fontFamily: 'var(--serif)', fontSize: 22, lineHeight: 1.1, marginTop: 8 }}>{course}</div>
      <div style={{ fontFamily: 'var(--sans)', fontSize: 11, color: WF_DIM, marginTop: 4 }}>{subtitle}</div>

      <div style={{ marginTop: 14, padding: '10px 12px', borderRadius: 12,
        background: 'rgba(107,142,90,0.14)', border: `1px solid ${WF_FAINT}` }}>
        <div style={{ fontSize: 10, color: WF_DIM, letterSpacing: 1, textTransform: 'uppercase' }}>Last played</div>
        <div style={{ fontFamily: 'var(--mono)', fontSize: 13, color: WF_INK, marginTop: 2 }}>May 12 · <span style={{ color: WF_FAIRWAY_2 }}>84</span></div>
      </div>

      <div style={{ marginTop: 'auto', display: 'flex', flexDirection: 'column', gap: 6 }}>
        <button style={{ height: 36, borderRadius: 18, border: 'none',
          background: '#6B8E5A', color: '#0a120c', fontFamily: 'var(--sans)', fontWeight: 600, fontSize: 13 }}>
          Start round
        </button>
        <button style={{ height: 28, borderRadius: 14, border: 'none',
          background: 'transparent', color: WF_DIM, fontFamily: 'var(--sans)', fontSize: 11 }}>
          Not here
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Score input — strokes + putts dial
// ─────────────────────────────────────────────────────────────
function Watch_Score({ hole = 4, par = 4, strokes = 4, putts = 2, onStrokes, onPutts, active = 'strokes' }) {
  const dot = (filled, key) => (
    <span key={key} style={{ width: 8, height: 8, borderRadius: 4,
      background: filled ? WF_FAIRWAY_2 : 'transparent',
      border: `1.2px solid ${filled ? WF_FAIRWAY_2 : WF_FAINT}` }}/>
  );
  const delta = strokes - par;
  const deltaLabel = delta < 0 ? `${delta}` : delta === 0 ? 'E' : `+${delta}`;
  const deltaColor = delta < 0 ? WF_FAIRWAY_2 : delta === 0 ? WF_INK : WF_PIN;

  return (
    <div style={{ position: 'absolute', inset: 0, padding: '26px 16px 12px',
      color: WF_INK, fontFamily: 'var(--sans)', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 12, fontWeight: 600, color: WF_FAIRWAY_2 }}>Hole {hole}</span>
        <span style={{ fontFamily: 'var(--mono)', fontSize: 10, color: WF_DIM, letterSpacing: 1.5 }}>PAR {par}</span>
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 14 }}>
        {/* Strokes */}
        <div style={{ borderRadius: 12, padding: '8px 10px',
          background: active === 'strokes' ? 'rgba(148,178,128,0.14)' : 'transparent',
          border: `1px solid ${active === 'strokes' ? 'rgba(148,178,128,0.4)' : WF_FAINT}` }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <span style={{ fontSize: 10, color: WF_DIM, letterSpacing: 1.4, textTransform: 'uppercase' }}>Strokes</span>
            <span className="tabular" style={{ fontSize: 11, fontFamily: 'var(--mono)', color: deltaColor }}>{deltaLabel}</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 2 }}>
            <span className="tabular" style={{ fontSize: 36, fontWeight: 600, lineHeight: 1 }}>{strokes}</span>
            <div style={{ display: 'flex', gap: 4 }}>
              {[1,2,3,4,5,6,7].map(i => dot(i <= strokes, i))}
            </div>
          </div>
        </div>

        {/* Putts */}
        <div style={{ borderRadius: 12, padding: '8px 10px',
          background: active === 'putts' ? 'rgba(148,178,128,0.14)' : 'transparent',
          border: `1px solid ${active === 'putts' ? 'rgba(148,178,128,0.4)' : WF_FAINT}` }}>
          <div style={{ fontSize: 10, color: WF_DIM, letterSpacing: 1.4, textTransform: 'uppercase' }}>Putts</div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 2 }}>
            <span className="tabular" style={{ fontSize: 28, fontWeight: 600, lineHeight: 1 }}>{putts}</span>
            <div style={{ display: 'flex', gap: 4 }}>
              {[1,2,3,4].map(i => dot(i <= putts, i))}
            </div>
          </div>
        </div>
      </div>

      <div style={{ fontFamily: 'var(--mono)', fontSize: 9, color: WF_DIM, letterSpacing: 1.5,
        textAlign: 'center', marginTop: 4 }}>
        TURN CROWN · TAP TO SWAP
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Hole advance — finished hole, ready for next
// ─────────────────────────────────────────────────────────────
function Watch_HoleAdvance({ from = 4, to = 5, scored = 5, par = 4 }) {
  const delta = scored - par;
  const word = delta === -2 ? 'Eagle' : delta === -1 ? 'Birdie' : delta === 0 ? 'Par' : delta === 1 ? 'Bogey' : delta === 2 ? 'Double' : `+${delta}`;
  const color = delta < 0 ? WF_FAIRWAY_2 : delta === 0 ? WF_INK : WF_PIN;
  return (
    <div style={{ position: 'absolute', inset: 0, padding: '32px 16px 14px',
      color: WF_INK, fontFamily: 'var(--sans)', display: 'flex', flexDirection: 'column',
      background: 'radial-gradient(ellipse at 50% 0%, rgba(107,142,90,0.2) 0%, #000 70%)' }}>
      <div style={{ fontFamily: 'var(--mono)', fontSize: 9, color: WF_DIM, letterSpacing: 2 }}>HOLE {from} COMPLETE</div>
      <div style={{ marginTop: 14 }}>
        <div className="tabular" style={{ fontFamily: 'var(--serif)', fontSize: 76, lineHeight: 1, color }}>
          {scored}
        </div>
        <div style={{ fontFamily: 'var(--serif)', fontStyle: 'italic', fontSize: 22, color, marginTop: 2 }}>{word}</div>
      </div>
      <div style={{ marginTop: 16, fontFamily: 'var(--mono)', fontSize: 10, color: WF_DIM, letterSpacing: 1.4 }}>
        ROUND <span style={{ color: WF_INK }}>+5</span> · THRU {from}/18
      </div>
      <button style={{ marginTop: 'auto', height: 38, borderRadius: 19, border: 'none',
        background: WF_FAIRWAY_2, color: '#0a120c', fontFamily: 'var(--sans)', fontWeight: 600, fontSize: 13,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
        Hole {to} <span style={{ opacity: 0.7 }}>→</span>
      </button>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Voice / manual yardage input
// ─────────────────────────────────────────────────────────────
function Watch_Voice({ listening = true, heard = '', parsed }) {
  return (
    <div style={{ position: 'absolute', inset: 0, padding: '28px 16px 14px',
      color: WF_INK, fontFamily: 'var(--sans)', display: 'flex', flexDirection: 'column',
      background: 'radial-gradient(ellipse at 50% 60%, rgba(184,70,58,0.18) 0%, #000 75%)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <span style={{ width: 8, height: 8, borderRadius: 4, background: WF_PIN,
          animation: 'pulse 1.4s ease-in-out infinite' }}/>
        <span style={{ fontFamily: 'var(--mono)', fontSize: 10, color: WF_PIN, letterSpacing: 2 }}>LISTENING</span>
      </div>
      <style>{`@keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}`}</style>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
        {/* Waveform */}
        <div style={{ display: 'flex', gap: 3, alignItems: 'center', justifyContent: 'center', height: 32, marginBottom: 16 }}>
          {[14, 22, 10, 28, 18, 30, 14, 24, 16, 20, 12, 26, 14, 22, 10].map((h, i) => (
            <span key={i} style={{ width: 3, height: h, background: WF_FAIRWAY_2, opacity: 0.4 + (h / 60),
              borderRadius: 2 }}/>
          ))}
        </div>
        <div style={{ fontFamily: 'var(--serif)', fontStyle: 'italic', fontSize: 16, color: WF_DIM, textAlign: 'center', lineHeight: 1.3 }}>
          "{heard || '132 yards, north'}"
        </div>
        {parsed && (
          <div style={{ marginTop: 14, display: 'flex', justifyContent: 'center', gap: 14, alignItems: 'baseline' }}>
            <div>
              <div style={{ fontFamily: 'var(--mono)', fontSize: 8, color: WF_DIM, letterSpacing: 1.6 }}>YARDS</div>
              <div className="tabular" style={{ fontSize: 28, fontWeight: 600, color: WF_INK }}>{parsed.yards}</div>
            </div>
            <div style={{ width: 1, height: 24, background: WF_FAINT }}/>
            <div>
              <div style={{ fontFamily: 'var(--mono)', fontSize: 8, color: WF_DIM, letterSpacing: 1.6 }}>BEARING</div>
              <div className="tabular" style={{ fontSize: 28, fontWeight: 600, color: WF_INK }}>{parsed.dir}°</div>
            </div>
          </div>
        )}
      </div>
      <div style={{ fontFamily: 'var(--mono)', fontSize: 9, color: WF_DIM, letterSpacing: 1.5, textAlign: 'center' }}>
        TAP TO CONFIRM
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Scorecard glance
// ─────────────────────────────────────────────────────────────
function Watch_Scorecard({ thru = 4, total = 5 }) {
  const holes = [
    { h: 1, par: 4, s: 5 },
    { h: 2, par: 3, s: 3 },
    { h: 3, par: 5, s: 6 },
    { h: 4, par: 4, s: '·' },
  ];
  return (
    <div style={{ position: 'absolute', inset: 0, padding: '26px 14px 12px',
      color: WF_INK, fontFamily: 'var(--sans)', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <span style={{ fontSize: 12, fontWeight: 600, color: WF_FAIRWAY_2 }}>Round</span>
        <span className="tabular" style={{ fontFamily: 'var(--mono)', fontSize: 11, color: WF_DIM }}>THRU {thru}/18</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 4 }}>
        <span className="tabular" style={{ fontSize: 48, fontWeight: 600, lineHeight: 1 }}>14</span>
        <span style={{ fontFamily: 'var(--mono)', fontSize: 12, color: WF_PIN }}>+{total - 12}</span>
      </div>

      <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 4 }}>
        {holes.map(h => (
          <div key={h.h} style={{ display: 'flex', alignItems: 'center', gap: 8,
            fontFamily: 'var(--mono)', fontSize: 12,
            padding: '4px 8px', borderRadius: 6,
            background: h.s === '·' ? 'rgba(148,178,128,0.14)' : 'transparent' }}>
            <span style={{ width: 14, color: WF_DIM }}>{h.h}</span>
            <span style={{ width: 14, color: WF_DIM, fontSize: 9 }}>P{h.par}</span>
            <span className="tabular" style={{ marginLeft: 'auto', fontSize: 14, fontWeight: 600,
              color: h.s === '·' ? WF_FAIRWAY_2 : (typeof h.s === 'number' && h.s > h.par ? WF_PIN : WF_INK) }}>{h.s}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { Watch_CourseConfirm, Watch_Score, Watch_HoleAdvance, Watch_Voice, Watch_Scorecard });
