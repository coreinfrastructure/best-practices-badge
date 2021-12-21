# Information for Translators

## Welcome

Thank you for translating for the OpenSSF Best Practices badge project! *Any* help you can give is greatly appreciated.

## How to Translate

We normally use a web service at <https://translation.io> to manage translations. This web interface shows translations to be done & provides some help. You should have already received an invitation from translation.io for your account that we’ve made for you. After you log in, select "cii-best-practices-badge” as the project and the language you’ll work on.

You will then see the “main page”. At the top left you’ll see a “filters” dropdown followed by a text box saying “Search (key, source, or target) - this lets you select what translatable text to show or translate. Below that, on the left, is the list of translatable text meeting those filter & search criteria; one translatable text will be selected (it will probably be “Account Activated!”). If you use your mouse to hover over a translatable text, its color will change and its key will be displayed in small print. On the lower right is a copy of the selected translatable text, and the bottom right is its current translation (edit here to change it). When you change the translation text, you’re telling the system for that given key what the correct translated text is.

If you’re working on a *new* locale (language) translation, we recommend that you prioritize the translations for the front page first.  On the left-hand side of the screen, to the right of the word "Filters", is a text box.  Use that text box to search for the keys `hello`, `static_pages.home.`, `layouts.` and `locale_name.` - and translate those.  Once those are done, the front page would be (essentially) translated. The `hello` key is a sanity check that isn’t directly displayed but is used in some of our tests to detect locale display problems. After that, `users.`, `projects.` and `headings.` are good places to go.  The `criteria_overall.` and rcriteria.0.` keys are in many ways the heart of this.

If you’re working on an *existing* translation, the top priority is to translate all text not already translated. On the top left, click on “Filters” and select “Untranslated”, then click outside. You’ll then see on the left-hand-side the list of translatable text that is not currently translated. Use your mouse to select any one you want, then on the bottom right type in its translation. On the upper right will be a suggested translation; sometimes they’re great, sometimes they’re awful. After that, it’d be great to fix text that has changed since it was translated. On the top left, click on “Filters”, unselect “Untranslated”, and select “source changed”. What’s changed is highlighted on the left-hand-side. After those are done, unselect “Untranslated” and select “source changed”.

## Some Random Tips

You’ll see some href=”...” entries with URLs. Change any initial “/en/“ in a URL to your locale (e.g., change it to “/fr/” for French or “/zh-CN/” for Simplified Chinese).

If there are two translators for a given locale, we suggest that one start from the bottom of the list & go up, while the other start from the top & goes down. That way, if you happen to be working at the same time it won’t matter.

If you want to type into a YAML text file & upload that instead, we have a mechanism for doing that, but that’s a little more complicated for getting started. Let me know if you want to go that route.

Once you update any translations, we'll later move the translations to the final website. We’ll *gladly* do that part for you!

Pluralization is tricky in some languages (e.g., Russian). Rails specially handles pluralization when the special field "count" is used.  It then looks for keys which in the general case can be {zero, one, two, few, many, other}. The key "one" isn't necessarily used for just 1 in a language. For more information, see the Unicode plural rules: <http://cldr.unicode.org/index/cldr-spec/plural-rules> <http://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html>. We include keys for the forms we don't use in some languages so that  translation.io will generate the keys in the translation files.

## More information

For more technical information about translation, see <./implementation.md>.
The list of translators is restricted (since it reveals email addresses); if you are authorized, you can log into translation.io or view the [information on translators page](https://docs.google.com/document/d/13XioAIW0g0tIRtBZCSIy7NnrAbC3K6R8JWC22H37vIc/edit).

Note that users decide which locale to view via the URL page, e.g., /en/ for English or /fr/ for French. A URL without the locale prefix is redirected to the best matching locale based on the user's web browser settings; users can manually switch to another locale by changing the URL or selecting a drop-down list.
