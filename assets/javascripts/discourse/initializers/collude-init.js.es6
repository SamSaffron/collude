import { withPluginApi } from "discourse/lib/plugin-api";
import {
  default as computed,
  on,
  observes
} from "discourse-common/utils/decorators";
import {
  setupCollusion,
  teardownCollusion,
  performCollusion,
  toggleCollusion
} from "../lib/collude";
import Composer from "discourse/models/composer";

const COLLUDE_ACTION = "colludeOnTopic";

function initWithApi(api) {
  api.includePostAttributes("collude");
  api.addPostMenuButton("collude", post => {
    if (!post.collude || !post.canEdit) {
      return;
    }

    return {
      action: COLLUDE_ACTION,
      icon: "far-handshake",
      label: "collude.collaborate",
      title: "collude.button_title",
      className: "collude create",
      position: "last"
    };
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
    html(attrs, state) {
      const contents = this._super(...arguments);

      if (!this.currentUser.staff || attrs.post_number != 1) {
        return contents;
      }

      contents.push(
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
    creatingCollusion: Em.computed.equal("action", COLLUDE_ACTION)
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

  api.modifyClass("controller:composer", {
    open(opts) {
      return this._super(opts).then(() => {
        if (opts.action == COLLUDE_ACTION) {
          setupCollusion(this.model);
        }
      });
    },

    collapse() {
      if (this.get("model.action") == COLLUDE_ACTION) {
        return this.close();
      }
      return this._super();
    },

    close() {
      if (this.get("model.action") == COLLUDE_ACTION) {
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
      if (this.get("model.action") == COLLUDE_ACTION) {
        performCollusion(this.model);
      }
    },

    _saveDraft() {
      if (this.get("model.action") == COLLUDE_ACTION) {
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
