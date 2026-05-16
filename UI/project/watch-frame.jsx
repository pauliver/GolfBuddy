// WatchFrame — Apple Watch Ultra-style bezel.
// Screen: 410×502 (Ultra). Frame adds bezel + crown + side button.
// Usage: <WatchFrame dark><WatchScreen>...</WatchScreen></WatchFrame>

function WatchFrame({ children, dark = false, label, time = '9:41' }) {
  const screenW = 205;
  const screenH = 251;
  const bezelX = 12;
  const bezelTop = 14;
  const bezelBot = 14;
  const totalW = screenW + bezelX * 2;
  const totalH = screenH + bezelTop + bezelBot;
  const radius = 38;

  // Titanium body
  const bodyBg = 'linear-gradient(135deg, #4a4640 0%, #2c2925 45%, #3a3631 100%)';

  return (
    <div style={{ position: 'relative', width: totalW + 12, height: totalH }}>
      {/* Action button (orange, left side) */}
      <div style={{
        position: 'absolute', left: -3, top: totalH * 0.42, width: 5, height: 26,
        background: 'linear-gradient(180deg, #C45A2E, #8E3B1C)',
        borderRadius: '2px 0 0 2px',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.25), 0 1px 1px rgba(0,0,0,0.3)',
      }} />
      {/* Crown (right side, upper) */}
      <div style={{
        position: 'absolute', right: 0, top: totalH * 0.32, width: 12, height: 30,
        background: bodyBg, borderRadius: '0 4px 4px 0',
        boxShadow: 'inset 0 -1px 1px rgba(0,0,0,0.5), inset 1px 0 0 rgba(255,255,255,0.05)',
      }}>
        <div style={{ position: 'absolute', right: 2, top: 4, bottom: 4, width: 6, borderRadius: 1,
          background: 'repeating-linear-gradient(180deg, #1f1c19 0 1.5px, #4a4640 1.5px 3px)',
        }} />
      </div>
      {/* Side button (right side, lower) */}
      <div style={{
        position: 'absolute', right: 0, top: totalH * 0.58, width: 8, height: 36,
        background: bodyBg, borderRadius: '0 3px 3px 0',
        boxShadow: 'inset 0 -1px 1px rgba(0,0,0,0.5)',
      }} />

      {/* Frame body */}
      <div style={{
        width: totalW, height: totalH,
        background: bodyBg,
        borderRadius: radius,
        boxShadow: `
          inset 0 1px 0 rgba(255,255,255,0.08),
          inset 0 -1px 0 rgba(0,0,0,0.4),
          0 24px 60px -20px rgba(0,0,0,0.5),
          0 8px 20px -8px rgba(0,0,0,0.3)`,
        position: 'relative', overflow: 'hidden',
      }}>
        {/* Screen */}
        <div style={{
          position: 'absolute',
          left: bezelX, top: bezelTop,
          width: screenW, height: screenH,
          background: '#000',
          borderRadius: radius - 6,
          overflow: 'hidden',
          boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.04)',
        }}>
          {/* Time label — small, top center, native style */}
          <div style={{
            position: 'absolute', top: 5, left: 0, right: 0, textAlign: 'center',
            fontFamily: '-apple-system, "SF Pro Rounded", system-ui',
            fontSize: 12, fontWeight: 600, color: '#ff9b3d',
            letterSpacing: 0.1, zIndex: 30, pointerEvents: 'none',
          }}>{time}</div>
          {children}
        </div>
      </div>
      {/* Optional caption below */}
      {label && <div style={{
        position: 'absolute', left: 0, right: 0, top: totalH + 10, textAlign: 'center',
        fontFamily: 'var(--sans)', fontSize: 11, color: 'rgba(60,50,40,0.65)',
        letterSpacing: 0.2, textTransform: 'uppercase',
      }}>{label}</div>}
    </div>
  );
}

// WatchScreen — fills the watch screen, applies theme
function WatchScreen({ children, dark = true, style = {} }) {
  return (
    <div className={`watch-screen ${dark ? 'dark' : ''}`} style={style}>
      <div className="watch-screen-inner">{children}</div>
    </div>
  );
}

Object.assign(window, { WatchFrame, WatchScreen });
