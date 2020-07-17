import { withPluginApi } from "discourse/lib/plugin-api";
import { on, observes } from "discourse-common/utils/decorators";
import {
  setupCollusion,
  teardownCollusion,
  performCollusion
} from "../lib/collude";
import Composer from "discourse/models/composer";
import { computed } from "@ember/object";

import { SAVE_LABELS, SAVE_ICONS } from "discourse/models/composer";

const COLLUDE_ACTION = "colludeOnTopic";

function initWithApi(api) {
  SAVE_LABELS[[COLLUDE_ACTION]] = "composer.save_edit";
  SAVE_ICONS[[COLLUDE_ACTION]] = "pencil-alt";

  api.includePostAttributes("collude");
  api.addPostMenuButton("collude", post => {
    if (!post.collude || !post.canEdit) {
      return;
    }

    const result = {
      action: COLLUDE_ACTION,
      icon: "far-handshake",
      title: "collude.button_title",
      className: "collude create fade-out",
      position: "last"
    };

    if (!post.mobileView) {
      result.label = "collude.collaborate";
    }

    return result;
  });

  api.reopenWidget("post-menu", {
    menuItems() {
      const result = this._super(...arguments);

      if (this.attrs.collude) {
        this.attrs.wiki = false;

        if (result.includes("edit")) {
          result.splice(result.indexOf("edit"), 1);
        }
      }

      return result;
    },

    colludeOnTopic() {
      const post = this.findAncestorModel();
      this.appEvents.trigger("collude-on-topic", post);
    }
  });

  api.reopenWidget("post-admin-menu", {
    html(attrs) {
      const contents = this._super(...arguments);

      if (
        !this.currentUser.staff ||
        attrs.post_number !== 1 ||
        !contents.children
      ) {
        return contents;
      }

      contents.children.push(
        this.attach("post-admin-menu-button", {
          action: "toggleCollusion",
          icon: "far-handshake",
          className: "admin-collude",
          label: attrs.collude
            ? "collude.disable_collusion"
            : "collude.enable_collusion"
        })
      );

      return contents;
    },

    toggleCollusion() {
      const post = this.findAncestorModel();

      post
        .updatePostField("collude", !!!post.get("collude"))
        .then(() => this.scheduleRerender());
    }
  });

  api.modifyClass("component:scrolling-post-stream", {
    colludeOnTopic() {
      this.appEvents.trigger("collude-on-topic");
    }
  });

  api.modifyClass("model:composer", {
    creatingCollusion: computed.equal("action", COLLUDE_ACTION)
  });

  api.modifyClass("controller:topic", {
    init() {
      this._super(...arguments);

      this.appEvents.on("collude-on-topic", post => {
        const draftKey = post.get("topic.draft_key");
        const draftSequence = post.get("topic.draft_sequence");

        this.get("composer").open({
          post,
          action: COLLUDE_ACTION,
          draftKey,
          draftSequence
        });
      });
    },

    willDestroy() {
      this.appEvents.off("collude-on-topic", this);
      this._super(...arguments);
    }
  });

  Composer.serializeToDraft("changesets");
  Composer.serializeToDraft("colludeDone");

  api.modifyClass("controller:composer", {
    open(opts) {
      return this._super(opts).then(() => {
        if (opts.action === COLLUDE_ACTION) {
          setupCollusion(this.model);
        }
      });
    },

    collapse() {
      if (this.get("model.action") === COLLUDE_ACTION) {
        return this.close();
      }
      return this._super();
    },

    close() {
      if (this.get("model.action") === COLLUDE_ACTION) {
        teardownCollusion(this.model);
      }
      return this._super();
    },

    @on("init")
    _listenForClose() {
      this.appEvents.on("composer:close", () => {
        this.close();
      });
    },

    @observes("model.reply")
    _handleCollusion() {
      if (this.get("model.action") === COLLUDE_ACTION) {
        performCollusion(this.model);
      }
    },

    _saveDraft() {
      if (this.get("model.action") === COLLUDE_ACTION) {
        return;
      }
      return this._super();
    }
  });
}

export default {
  name: "collude",
  initialize: () => {
    withPluginApi("0.8.6", initWithApi);
  }
};
