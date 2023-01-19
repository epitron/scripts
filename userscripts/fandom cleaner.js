// ==UserScript==
// @name Fandom.com --- Cleaner Wikis Userscript
// @description Removes all of the non-wiki parts of fandom.com wikis, reduces the footprint of the search overlay, and forces the search overlay to use wiki-theme colors. Based on "Fandom - Remove Garbage" by jurassicplayer.
// @namespace https://greasyfork.org/users/797186
// @author G3T
// @version 1.0.7
// @license unlicense
// @grant GM_addStyle
// @run-at document-end
// @include http://fandom.com/*
// @include https://fandom.com/*
// @include http://*.fandom.com/*
// @include https://*.fandom.com/*
// ==/UserScript==

(function() {
let css = `


    #mixed-content-footer,
    .wds-global-footer,
    #WikiaBarWrapper,
    .wds-global-navigation__content-bar-left,
    .global-navigation,
    .fandom-sticky-header,
    .gpt-ad,
    .ad-slot-placeholder.top-leaderboard.is-loading,
    .page__right-rail,
    .search-modal::before,
    form[class^="SearchInput-module_form__"] .wds-icon,
    .notifications-placeholder,
    .top-ads-container,
    .instant-suggestion,
    .unified-search__result.marketplace {
        display: none;
    }

    .main-container {
        width: 100%;
        margin-left: 0px;
    }

    .community-header-wrapper {
        height: auto;
    }

    .search-modal {
        position: absolute;
        bottom: auto;
        left: auto;
    }

    .search-modal__content {
        width: 420px;
        top: 20px;
        right: -3px;
        min-height: auto;
        background-color: var(--theme-page-background-color--secondary);
        border: 1px solid var(--theme-border-color);
        animation: none;
    }

    form[class^="SearchInput-module_form__"] {
        border-bottom: 2px solid var(--theme-border-color);
        color: var(--theme-border-color);
    }

    form[class^="SearchInput-module_form__"] .wds-button {
        --wds-primary-button-background-color: var(--theme-accent-color);
        --wds-primary-button-background-color--hover: var(--theme-accent-color--hover);
        --wds-primary-button-label-color: var(--theme-accent-label-color);
    }

    input[class^="SearchInput-module_input__"] {
        color: var(--theme-page-text-color);
        border-left: none;
        padding: 0;
    }

    a[class^="SearchResults-module_seeAllResults"] {
        color: var(--theme-link-color) !important;
    }
`;
if (typeof GM_addStyle !== "undefined") {
  GM_addStyle(css);
} else {
  let styleNode = document.createElement("style");
  styleNode.appendChild(document.createTextNode(css));
  (document.querySelector("head") || document.documentElement).appendChild(styleNode);
}
})();
