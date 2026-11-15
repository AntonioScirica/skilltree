// Cloud mode (optional). Leave both empty to use the map locally with files, as in the Quick start.
// To turn it on, follow cloud/README.md. These two values are public by nature: they end up in the browser of anyone
// who opens the page. What protects the data are the rules in cloud/schema.sql, not the secrecy of this key.
// NEVER put the "service_role" / "secret" key here: that one stays in .env on your computer.
window.CLOUD = {
  url: '',   // e.g. https://abcdefgh.supabase.co
  key: '',   // anon / publishable key
};
