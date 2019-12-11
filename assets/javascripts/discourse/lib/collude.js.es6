import { ajax } from "discourse/lib/ajax";
import { expandCollusion } from "./collude-dom";
import User from "discourse/models/user";

const messageBus = function() {
  return Discourse.__container__.lookup("message-bus:main");
};

const store = function() {
  return Discourse.__container__.lookup("service:store");
};

// connect to server and request initial document
const setupCollusion = function(composer) {
  const resolve = data => {
    if (User.currentProp("id") == data.collusion.actor_id) {
      composer.set("changesets.confirmed", data.collusion.changeset);
    } else {
      composer.set("reply", data.collusion.value || "");
      composer.set("changesets", {
        performed: data.collusion.changeset,
        submitted: data.collusion.changeset,
        confirmed: data.collusion.changeset
      });
    }
  };

  expandCollusion();
  messageBus().subscribe(
    `/collusions/${composer.get("post.topic_id")}`,
    resolve
  );

  return ajax(`/posts/${composer.get("post.id")}/latest_collusion`).then(
    resolve
  );
};

// push local changes to the server
const performCollusion = function(composer) {
  if (!composer.changesets) {
    return;
  }

  composer.set(
    "changesets.performed",
    resolveChangeset(composer.changesets.submitted, {
      length_before: 0,
      length_after: composer.reply.length,
      changes: [composer.reply]
    })
  );

  return putCollusion(composer);
};

const toggleCollusion = function(postId) {
  return store()
    .find("post", postId)
    .then(post => {
      post.set("collude", !post.collude);
      return ajax(`/collusions/${post.topic_id}/toggle`, { type: "POST" });
    });
};

//// private

const putCollusion = _.debounce(composer => {
  if (_.isEqual(composer.changesets.performed, composer.changesets.submitted)) {
    return;
  }

  composer.set("changesets.submitted", composer.changesets.performed);
  composer.saveDraft();
}, Discourse.SiteSettings.collude_debounce);

const teardownCollusion = function(composer) {
  messageBus().unsubscribe(`/collusions/${composer.get("post.topic_id")}`);
};

const resolveChangeset = function(prev, next) {
  if (_.isEqual(prev, next)) {
    return prev;
  }
  return {
    length_before: prev.length_after,
    length_after: next.length_after,
    changes: resolveChanges(prev, next)
  };
};

const resolveChanges = function(prev, next) {
  const _prev = fullChangesArray(prev);
  const _next = fullChangesArray(next);
  return compressChanges(
    _.range(_next.length).map(index => {
      if (_next[index] == _prev[index]) {
        return index;
      }
      return (
        (typeof _next[index] == "string" && _next[index]) ||
        (typeof _prev[index] == "string" && _prev[index]) ||
        index
      );
    })
  );
};

const compressChanges = function(expanded) {
  return _.reduce(
    expanded,
    (array, change) => {
      let prevMode =
        (_.last(array) || []).slice(0, 2) == "øø" ? "unchanged" : "changed";
      let currMode = typeof change == "number" ? "unchanged" : "changed";

      if (prevMode == currMode) {
        let curr = array.pop() || [];
        switch (prevMode) {
          case "changed":
            array.push(`${curr}${change}`);
            break;
          case "unchanged":
            array.push(`${curr.split("-")[0]}-${change}`);
            break;
        }
      } else {
        switch (currMode) {
          case "changed":
            array.push(change);
            break;
          case "unchanged":
            array.push(`øø${change}-${change}`);
            break;
        }
      }

      return array;
    },
    []
  );
};

const fullChangesArray = function(changeset) {
  return _.reduce(
    changeset.changes,
    (array, change) => {
      if (change.slice(0, 2) == "øø") {
        let [b, e] = change.replace("øø", "").split("-");
        return array.concat(_.range(parseInt(b), parseInt(e) + 1));
      } else {
        return array.concat(change.split(""));
      }
    },
    []
  );
};

export { setupCollusion, teardownCollusion, performCollusion, toggleCollusion };
