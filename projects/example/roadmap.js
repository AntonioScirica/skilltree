// Example project (invented): a small bakery wants a website with online pre-orders.
// One file is enough for a small project; big ones can be split (levels-a.js, levels-b.js, … loaded alphabetically,
// roadmap.js last). The map reads window.ROADMAP.
window.ROADMAP = {
  name: 'Harbor Bakery · Website and pre-orders',
  lang: 'en',            // language of the map interface: 'en' or 'it'
  referente: 'Maya',     // the client's single point of contact; shown in the side panel
  start: null,           // Monday of week 1, 'YYYY-MM-DD'. null = pick the week by hand in the panel

  levels: [
    {
      id: 'kickoff', fase: 'Kickoff', t: 'Contract, accounts, setup', w: [0, 0],
      d: 'Everything that must exist before day one. Work starts when the first instalment is paid.',
      nodes: [
        { id: 'contract', t: 'Contract', tasks: ['Send the signed proposal', 'Receive the countersigned copy', 'Name the single point of contact', 'Issue invoice for instalment 1', 'Instalment 1 received'] },
        { id: 'setup', t: 'Technical setup', tasks: ['Create the repository', 'Scaffold the app', 'Set up staging environment', 'Add lint and type checks to CI', 'Add secret scanning to CI', 'Write the project README'] },
      ],
    },
    {
      id: 'design', fase: 'Design', t: 'Look and prototype', w: [1, 2],
      d: 'Style fixed, prototype approved. After approval the design is final.',
      nodes: [
        { id: 'style', t: 'Visual direction', tasks: ['Collect logo, photos, reference sites', 'Draft colours and typography', 'Design the home page', 'Export the proposal as PDF', 'Written approval received'] },
        { id: 'proto', t: 'Clickable prototype', tasks: ['Home and menu pages', 'Product page', 'Pre-order flow', 'Round 1 feedback applied', 'Round 2 feedback applied', 'Written approval received'] },
        { id: 'pc1', t: 'Test plan, phase 1', tasks: ['Write test cases per requirement', 'Send to the client', 'Approved in writing'] },
      ],
    },
    {
      id: 'p1', fase: 'Phase 1', t: 'Website and catalogue', w: [3, 5],
      d: 'Public site with the product catalogue, editable by the bakery.',
      nodes: [
        { id: 'db', t: 'Database and roles', tasks: ['Draw the database schema', 'Write the first migration', 'Enable row level security', 'Policy: staff can edit products', 'Policy: public reads published only', 'Test: anonymous cannot read drafts'] },
        { id: 'catalog', t: 'Product catalogue', tasks: ['Category list page', 'Product list with filters', 'Product page with allergens', 'Mark a product as sold out', 'Admin form to add a product', 'Test: sold-out cannot be ordered'] },
        { id: 'content', t: 'Editable pages', tasks: ['Home page blocks', 'About us page', 'Opening hours block', 'Contact page with map'] },
        { id: 'sec1', t: 'Security audit, phase 1', tasks: ['Review permissions per role', 'Check secrets and headers', 'Check vulnerable dependencies', 'Fixes closed before the test'] },
        { id: 'g1', gate: true, t: 'Phase 1 test · instalment 2', tasks: ['Run the test cases with the client', 'Test report signed', 'Issue invoice for instalment 2', 'Instalment 2 received'] },
      ],
    },
    {
      id: 'p2', fase: 'Phase 2', t: 'Pre-orders and launch', w: [6, 8],
      d: 'Customers pre-order for pick-up; the site goes live.',
      nodes: [
        { id: 'orders', t: 'Pre-orders', tasks: ['Basket with pick-up date', 'Cut-off time per product', 'Order confirmation email', 'Staff order list for the day', 'Mark an order as collected', 'Test: no order after cut-off', 'Test: totals computed on the server'] },
        { id: 'launch', t: 'Launch', tasks: ['Redirects from the old site', 'Sitemap submitted', 'Domain pointed to the new site', 'Client authorises go-live in writing'] },
        { id: 'secfin', t: 'Final security audit', tasks: ['Full review on production settings', 'Rotate secrets', 'Written summary delivered'] },
        { id: 'g2', gate: true, t: 'Final test · balance', tasks: ['Run the full test cases', 'Final report signed', 'Staff training session', 'Issue the final invoice', 'Balance received'] },
      ],
    },
  ],

  // What the client owes you. w = week by which it must arrive, per = the level that stops without it.
  client: [
    { id: 'c1', w: 0, per: 'kickoff', t: 'Signed proposal and first instalment' },
    { id: 'c2', w: 0, per: 'kickoff', t: 'Access to the domain registrar' },
    { id: 'c3', w: 1, per: 'design', t: 'Logo, photos of products and shop' },
    { id: 'c4', w: 1, per: 'design', t: 'Written approval of the visual direction' },
    { id: 'c5', w: 2, per: 'design', t: 'Prototype feedback, one written note per round' },
    { id: 'c6', w: 2, per: 'p1', t: 'Product list with prices and allergens' },
    { id: 'c7', w: 5, per: 'p1', t: 'Date for the phase 1 test' },
    { id: 'c8', w: 6, per: 'p2', t: 'Pick-up rules: days, hours, cut-off times' },
    { id: 'c9', w: 8, per: 'p2', t: 'Written go-live authorisation' },
  ],

  // What you owe the client. The weekly report is added by the map every week.
  send: [
    { id: 's1', w: 0, t: 'Invoice for instalment 1' },
    { id: 's2', w: 1, t: 'Visual direction PDF to approve' },
    { id: 's3', w: 2, t: 'Phase 1 test plan to approve' },
    { id: 's4', w: 5, t: 'Phase 1 test report and invoice for instalment 2' },
    { id: 's5', w: 8, t: 'Final report, documentation and final invoice' },
  ],

  rituals: [
    ['Every Friday', 'Send the client a short report of what is done and testable'],
    ['Every Friday', 'Chase in writing whatever is due next week'],
    ['End of each phase', 'Security audit, fixes, then the test with the client'],
    ['Every delay on their side', 'Tell them in writing that the schedule shifts by the same time'],
  ],
};
