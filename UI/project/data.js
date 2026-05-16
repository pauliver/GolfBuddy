// Fake course + history data. Yardages are realistic for a parkland course.

window.COURSES = [
  {
    id: 'arrowhead', name: 'Arrowhead Glen', subtitle: 'Sonoma, CA · Par 72',
    distance_mi: 1.8,
    holes: [
      { n: 1, par: 4, yards: 392, fcb: [378, 392, 408], shape: 'dogleg-r', hazards: ['bunker-l'] },
      { n: 2, par: 3, yards: 168, fcb: [156, 168, 178], shape: 'straight', hazards: ['water-f'] },
      { n: 3, par: 5, yards: 538, fcb: [522, 538, 552], shape: 'dogleg-l', hazards: ['bunker-r'] },
      { n: 4, par: 4, yards: 415, fcb: [402, 415, 428], shape: 'straight' },
      { n: 5, par: 4, yards: 360, fcb: [348, 360, 374], shape: 'dogleg-r' },
      { n: 6, par: 3, yards: 195, fcb: [184, 195, 206], shape: 'straight', hazards: ['water-r'] },
      { n: 7, par: 5, yards: 562, fcb: [548, 562, 578], shape: 'straight' },
      { n: 8, par: 4, yards: 428, fcb: [415, 428, 441], shape: 'dogleg-l' },
      { n: 9, par: 4, yards: 380, fcb: [368, 380, 394], shape: 'straight' },
      { n: 10, par: 4, yards: 405, fcb: [392, 405, 418], shape: 'dogleg-r' },
      { n: 11, par: 3, yards: 152, fcb: [140, 152, 164], shape: 'straight' },
      { n: 12, par: 5, yards: 510, fcb: [498, 510, 524], shape: 'dogleg-l', hazards: ['water-l'] },
      { n: 13, par: 4, yards: 395, fcb: [382, 395, 408], shape: 'straight' },
      { n: 14, par: 4, yards: 422, fcb: [410, 422, 436], shape: 'dogleg-r' },
      { n: 15, par: 3, yards: 184, fcb: [172, 184, 198], shape: 'straight', hazards: ['bunker-f'] },
      { n: 16, par: 5, yards: 545, fcb: [530, 545, 560], shape: 'dogleg-l' },
      { n: 17, par: 4, yards: 388, fcb: [375, 388, 402], shape: 'straight' },
      { n: 18, par: 4, yards: 440, fcb: [428, 440, 454], shape: 'dogleg-l', hazards: ['water-f'] },
    ],
  },
  {
    id: 'driftwood', name: 'Driftwood Links', subtitle: 'Half Moon Bay · Par 71', distance_mi: 4.2,
    holes: [],
  },
  {
    id: 'cedar', name: 'Cedar Hollow', subtitle: 'Napa · Par 70', distance_mi: 6.7,
    holes: [],
  },
];

// History — last 8 rounds at Arrowhead, plus a couple elsewhere
window.HISTORY = [
  { id: 'r-7', date: 'May 12', course: 'Arrowhead Glen', score: 84, par: 72, fwy: 9, gir: 8, putts: 32 },
  { id: 'r-6', date: 'May 04', course: 'Arrowhead Glen', score: 88, par: 72, fwy: 7, gir: 6, putts: 34 },
  { id: 'r-5', date: 'Apr 28', course: 'Driftwood Links', score: 91, par: 71, fwy: 6, gir: 5, putts: 36 },
  { id: 'r-4', date: 'Apr 19', course: 'Arrowhead Glen', score: 86, par: 72, fwy: 8, gir: 7, putts: 33 },
  { id: 'r-3', date: 'Apr 10', course: 'Arrowhead Glen', score: 89, par: 72, fwy: 7, gir: 5, putts: 35 },
  { id: 'r-2', date: 'Mar 30', course: 'Cedar Hollow', score: 87, par: 70, fwy: 9, gir: 7, putts: 32 },
  { id: 'r-1', date: 'Mar 22', course: 'Arrowhead Glen', score: 92, par: 72, fwy: 5, gir: 4, putts: 37 },
  { id: 'r-0', date: 'Mar 15', course: 'Arrowhead Glen', score: 90, par: 72, fwy: 6, gir: 5, putts: 36 },
];

// Current round in progress — hole 4 of Arrowhead, par-4 415y
window.CURRENT = {
  course: 'arrowhead',
  startedAt: 'Today 9:14',
  hole: 4,
  yardsToPin: 142, // ball position → center
  fcb: [128, 142, 156],
  pinDirection: 28, // degrees from north (used for compass)
  scorecard: [
    { hole: 1, par: 4, strokes: 5, putts: 2 },
    { hole: 2, par: 3, strokes: 3, putts: 1 },
    { hole: 3, par: 5, strokes: 6, putts: 2 },
  ],
};
