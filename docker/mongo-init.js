db = db.getSiblingDB('itsupport');

db.createUser({
  user: "tdrs",
  pwd: "xpto",
  roles: [
    { role: "readWrite", db: "itsupport" },
    { role: "dbAdmin", db: "itsupport" }
  ]
});
