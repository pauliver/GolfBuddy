// Main app — DesignCanvas composition + Tweaks
// Three sections: Watch heroes (6 variants), Watch flow, Phone flow.

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "hero": "topo",
  "hole": 4,
  "showBand": "fcb",
  "phoneTheme": "light"
}/*EDITMODE-END*/;

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const course = window.COURSES[0];
  const hole = course.holes[Math.max(0, Math.min(17, t.hole - 1))];
  const heroProps = {
    hole: hole.n,
    par: hole.par,
    // For the hero display, treat the player as at a typical approach distance:
    yards: Math.max(80, hole.yards - 250),
    fcb: [
      Math.max(72, hole.fcb[0] - 250),
      Math.max(80, hole.fcb[1] - 250),
      Math.max(90, hole.fcb[2] - 250),
    ],
    pinDir: 28,
  };
  // Single-hole holes (par-3): use raw yards
  if (hole.par === 3) {
    heroProps.yards = hole.fcb[1];
    heroProps.fcb = hole.fcb;
  }

  const HeroComp = HEROES[t.hero]?.component || Hero_HIG;

  return (
    <React.Fragment>
      <DesignCanvas>
        {/* ── Section 1: HERO SHOWCASE — the chosen variant, large and alone ── */}
        <DCSection id="showcase" title="Hero showcase" subtitle={`The selected watch hero · ${HEROES[t.hero]?.name}`}>
          <DCArtboard id="chosen" label={`${HEROES[t.hero]?.name} · Hole ${heroProps.hole}`} width={300} height={360}>
            <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: 'radial-gradient(ellipse at 50% 40%, #f4ecd9 0%, #e6dcc1 100%)' }}>
              <WatchFrame dark>
                <HeroComp {...heroProps}/>
              </WatchFrame>
            </div>
          </DCArtboard>
          <DCArtboard id="chosen-context" label="In the wild — sleeve view" width={300} height={360}>
            <div style={{ position: 'absolute', inset: 0,
              background: 'linear-gradient(135deg, #4a3f30 0%, #2a2218 100%)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
              {/* subtle texture */}
              <div style={{ position: 'absolute', inset: 0, opacity: 0.18,
                backgroundImage: "url(\"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='200' height='200'><filter id='n'><feTurbulence baseFrequency='0.7' numOctaves='2'/></filter><rect width='100%25' height='100%25' filter='url(%23n)'/></svg>\")" }}/>
              {/* leather strap suggestion */}
              <div style={{ position: 'absolute', left: '50%', top: -20, bottom: -20, width: 120,
                transform: 'translateX(-50%) rotate(-6deg)',
                background: 'linear-gradient(90deg, transparent 0%, #5a4a36 12%, #7a6448 50%, #5a4a36 88%, transparent 100%)',
                borderRadius: 16,
                boxShadow: 'inset 0 0 30px rgba(0,0,0,0.4), 0 8px 30px rgba(0,0,0,0.4)' }}/>
              <div style={{ position: 'relative', transform: 'rotate(-6deg)' }}>
                <WatchFrame dark>
                  <HeroComp {...heroProps}/>
                </WatchFrame>
              </div>
            </div>
          </DCArtboard>
        </DCSection>

        {/* ── Section 2: HERO VARIATIONS — all 6 side by side ── */}
        <DCSection id="variants" title="Hero variations" subtitle="Six approaches to the main yardage screen — Apple HIG through editorial">
          {Object.entries(HEROES).map(([id, h]) => (
            <DCArtboard key={id} id={id} label={h.name} width={250} height={310}>
              <div style={{ position: 'absolute', inset: 0,
                background: id === t.hero ? 'rgba(107,142,90,0.10)' : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <WatchFrame dark>
                  <h.component {...heroProps}/>
                </WatchFrame>
              </div>
            </DCArtboard>
          ))}
        </DCSection>

        {/* ── Section 3: WATCH FLOW — surrounding screens ── */}
        <DCSection id="watch-flow" title="Watch flow" subtitle="The screens that wrap the hero — confirm, score, advance, manual">
          <DCArtboard id="course-confirm" label="On arrival" width={250} height={310}>
            <Centered>
              <WatchFrame dark>
                <Watch_CourseConfirm/>
              </WatchFrame>
            </Centered>
          </DCArtboard>
          <DCArtboard id="hero" label="Approach (selected)" width={250} height={310}>
            <Centered>
              <WatchFrame dark>
                <HeroComp {...heroProps}/>
              </WatchFrame>
            </Centered>
          </DCArtboard>
          <DCArtboard id="score" label="Score input" width={250} height={310}>
            <Centered>
              <WatchFrame dark>
                <Watch_Score hole={heroProps.hole} par={heroProps.par} strokes={5} putts={2}/>
              </WatchFrame>
            </Centered>
          </DCArtboard>
          <DCArtboard id="advance" label="Hole complete" width={250} height={310}>
            <Centered>
              <WatchFrame dark>
                <Watch_HoleAdvance from={heroProps.hole} to={heroProps.hole + 1} scored={5} par={heroProps.par}/>
              </WatchFrame>
            </Centered>
          </DCArtboard>
          <DCArtboard id="voice" label="Manual · voice" width={250} height={310}>
            <Centered>
              <WatchFrame dark>
                <Watch_Voice listening parsed={{ yards: 132, dir: 355 }}/>
              </WatchFrame>
            </Centered>
          </DCArtboard>
          <DCArtboard id="card" label="Scorecard glance" width={250} height={310}>
            <Centered>
              <WatchFrame dark>
                <Watch_Scorecard thru={3}/>
              </WatchFrame>
            </Centered>
          </DCArtboard>
        </DCSection>

        {/* ── Section 4: PHONE FLOW ── */}
        <DCSection id="phone" title="Phone" subtitle="On arrival · live round · scorecard · history · stats">
          <DCArtboard id="ph-confirm" label="GPS confirm" width={402} height={874}>
            <PhoneArtboard><Phone_CourseConfirm/></PhoneArtboard>
          </DCArtboard>
          <DCArtboard id="ph-home" label="Live round" width={402} height={874}>
            <PhoneArtboard><Phone_HomeInteractive setTweak={setTweak}/></PhoneArtboard>
          </DCArtboard>
          <DCArtboard id="ph-manual" label="Set distance manually" width={402} height={874}>
            <PhoneArtboard><Phone_Manual/></PhoneArtboard>
          </DCArtboard>
          <DCArtboard id="ph-card" label="Scorecard" width={402} height={874}>
            <PhoneArtboard><Phone_Scorecard/></PhoneArtboard>
          </DCArtboard>
          <DCArtboard id="ph-hist" label="History" width={402} height={874}>
            <PhoneArtboard><Phone_History/></PhoneArtboard>
          </DCArtboard>
          <DCArtboard id="ph-stats" label="Stats" width={402} height={874}>
            <PhoneArtboard><Phone_Stats/></PhoneArtboard>
          </DCArtboard>
        </DCSection>

        {/* ── Section 5: SYNCED MOMENT — phone + watch together ── */}
        <DCSection id="sync" title="Watch + phone, in sync" subtitle="The same moment, different surfaces">
          <DCArtboard id="sync-moment" label="Hole 4 · approaching the green" width={760} height={900}>
            <div style={{ position: 'absolute', inset: 0,
              background: 'radial-gradient(circle at 70% 30%, #f4ecd9 0%, #e0d2b0 100%)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 40, padding: 40 }}>
              <div style={{ position: 'relative', transform: 'rotate(-2deg)' }}>
                <PhoneArtboard><Phone_HomeInteractive setTweak={setTweak}/></PhoneArtboard>
              </div>
              <div style={{ position: 'relative', transform: 'rotate(3deg)' }}>
                <WatchFrame dark>
                  <HeroComp {...heroProps}/>
                </WatchFrame>
              </div>
            </div>
          </DCArtboard>
        </DCSection>
      </DesignCanvas>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Watch hero">
          <TweakSelect label="Variant" value={t.hero}
            options={Object.entries(HEROES).map(([id, h]) => ({ value: id, label: h.name }))}
            onChange={v => setTweak('hero', v)}/>
        </TweakSection>
        <TweakSection label="Live data">
          <TweakSlider label="Hole #" value={t.hole} min={1} max={18} step={1}
            onChange={v => setTweak('hole', v)}/>
        </TweakSection>
      </TweaksPanel>
    </React.Fragment>
  );
}

function Centered({ children }) {
  return <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{children}</div>;
}
function PhoneArtboard({ children }) {
  // The iOS frame already contains the device chrome; we render the phone-screen inside.
  return <IOSDevice width={402} height={874}>{children}</IOSDevice>;
}

// Phone home with internal interactivity (record stroke → score sheet)
function Phone_HomeInteractive({ setTweak }) {
  const [view, setView] = React.useState('home'); // home | score | card
  if (view === 'score') return <Phone_ScoreSheet onBack={() => setView('home')} onDone={() => setView('home')}/>;
  if (view === 'card') return <Phone_Scorecard onBack={() => setView('home')}/>;
  return <Phone_Home onScore={() => setView('score')} onScorecard={() => setView('card')}/>;
}

// Inline "record stroke" sheet — strokes + putts dial
function Phone_ScoreSheet({ onBack, onDone }) {
  const [strokes, setStrokes] = React.useState(5);
  const [putts, setPutts] = React.useState(2);
  const par = 4;
  const delta = strokes - par;
  const word = delta === -2 ? 'Eagle' : delta === -1 ? 'Birdie' : delta === 0 ? 'Par' : delta === 1 ? 'Bogey' : delta === 2 ? 'Double bogey' : `${delta > 0 ? '+' : ''}${delta}`;
  const color = delta < 0 ? 'var(--moss)' : delta === 0 ? 'var(--ink)' : 'var(--pin)';
  return (
    <div className="phone-screen grain">
      <IOSStatusBar/>
      <div style={{ padding: '4px 22px 12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <button onClick={onBack} style={{ background: 'none', border: 'none', color: 'var(--ink-soft)',
          fontFamily: 'var(--sans)', fontSize: 14 }}>Cancel</button>
        <div style={{ fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--ink-mute)', letterSpacing: 1.4 }}>HOLE 4 · PAR 4</div>
        <button onClick={onDone} style={{ background: 'none', border: 'none', color: 'var(--moss)',
          fontFamily: 'var(--sans)', fontSize: 14, fontWeight: 600 }}>Save</button>
      </div>

      <div style={{ padding: '40px 22px 0', textAlign: 'center' }}>
        <div style={{ fontFamily: 'var(--mono)', fontSize: 10, letterSpacing: 1.6, color: 'var(--ink-mute)' }}>SCORE</div>
        <div className="tabular" style={{ fontFamily: 'var(--serif)', fontSize: 120, lineHeight: 1, color, marginTop: 4 }}>{strokes}</div>
        <div style={{ fontFamily: 'var(--serif)', fontStyle: 'italic', fontSize: 22, color, marginTop: 2 }}>{word}</div>
      </div>

      {/* Strokes stepper */}
      <div style={{ marginTop: 28, padding: '0 22px' }}>
        <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--ink-mute)', letterSpacing: 1.6, marginBottom: 8 }}>STROKES</div>
        <div style={{ display: 'flex', gap: 8 }}>
          {[1, 2, 3, 4, 5, 6, 7, 8].map(n => {
            const on = n === strokes;
            return (
              <button key={n} onClick={() => setStrokes(n)} style={{ flex: 1, height: 44, borderRadius: 12,
                border: on ? 'none' : '1px solid var(--line)',
                background: on ? 'var(--moss)' : 'var(--paper-2)',
                color: on ? '#F2ECDD' : 'var(--ink)',
                fontFamily: 'var(--mono)', fontSize: 16, fontWeight: 600, cursor: 'pointer' }}>{n}</button>
            );
          })}
        </div>
      </div>

      <div style={{ marginTop: 18, padding: '0 22px' }}>
        <div style={{ fontFamily: 'var(--mono)', fontSize: 10, color: 'var(--ink-mute)', letterSpacing: 1.6, marginBottom: 8 }}>OF WHICH, PUTTS</div>
        <div style={{ display: 'flex', gap: 8 }}>
          {[0, 1, 2, 3, 4].map(n => {
            const on = n === putts;
            return (
              <button key={n} onClick={() => setPutts(n)} style={{ flex: 1, height: 44, borderRadius: 12,
                border: on ? 'none' : '1px solid var(--line)',
                background: on ? 'var(--ink)' : 'var(--paper-2)',
                color: on ? 'var(--paper)' : 'var(--ink)',
                fontFamily: 'var(--mono)', fontSize: 16, fontWeight: 600, cursor: 'pointer' }}>{n}</button>
            );
          })}
        </div>
      </div>

      <div style={{ flex: 1 }}/>

      <div style={{ padding: '0 22px 16px' }}>
        <button onClick={onDone} style={{ width: '100%', height: 52, borderRadius: 26, border: 'none',
          background: 'var(--moss)', color: '#F2ECDD',
          fontFamily: 'var(--sans)', fontWeight: 600, fontSize: 15 }}>
          Save and advance to hole 5
        </button>
      </div>
      <PhoneTabs active="home" onChange={() => {}}/>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
