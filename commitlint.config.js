module.exports = {
  extends: ['@commitlint/config-conventional'],
  ignores: [
    // Ignore merge commits
    (message) => message.startsWith('merge:'),
    // Ignore auto-generated release commits
    (message) => message.startsWith('chore(release):')
  ]
};