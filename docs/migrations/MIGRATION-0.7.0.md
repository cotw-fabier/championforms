# Migration Guide: v0.6.x → v0.7.0

## Overview

Two independent bodies of work landed in 0.7.0.

The **forms-as-data** work — serializable validators and conditional visibility
— is entirely additive. If that is all you came for, there is nothing to do.

The other half changes **which fields `FormResults` collects**, and that does
change behavior. This guide is about that half.

**Who this affects:**

- ✅ **Single-page forms**: no action needed. This release fixes a data-loss bug
  you may have been hitting without knowing.
- ⚠️ **Multi-page forms / wizards**: read [Multi-page forms](#multi-page-forms).
- ⚠️ **Anyone passing `checkForErrors: false`**: it now does what it says. Read
  [checkForErrors](#checkforerrors-is-honored).

**Migration time estimate:** zero for most apps; a few minutes for a wizard.

---

## The bug this fixes

`getResults` defaulted to `controller.activeFields` — the list of fields
*currently rendered*, maintained by the form widget's lifecycle. It is filled
when a `Form` mounts and emptied when it is torn down.

Teardown is Flutter's decision, not yours. A `Form` inside a `ListView` is
disposed the moment the list culls it, so:

```dart
// A form near the top of a long scrolling page.
final results = FormResults.getResults(controller: controller);
results.grab('title').asString();       // "" — after the user scrolled down
controller.getFieldValue<String>('title'); // "My Project" — still right here
```

The answer was never lost. Values and field definitions are never discarded on
dispose; only the list `getResults` happened to iterate was emptied. And
because `grab()` returns an empty accessor for an id it did not collect, the
failure was silent — `asString()` just returned `""`.

It also looked intermittent, which made it hard to trace: `EditableText` keeps
itself alive while focused, so the value only vanished once focus moved away.

`validateForm()` had the same root cause and a worse symptom — it validated
nothing and returned `true`, so a submit guarded by it went through unchecked.

## What changed

`getResults`, `getResultsReadOnly` and `validateForm` now work from
`FormController.registeredFields`: every field declared on the controller,
whether or not it is on screen.

The model, stated once:

> The controller holds the form's **schema**. A widget is a **view** of that
> schema. A field enters when it is *declared* — a `Form`'s `fields:` list, or
> `addFields`/`updateField` — and leaves only when it is *withdrawn* by
> `removeField` or `unregisterFields`. Mounting and unmounting say nothing
> about the schema.

`activeFields` still exists and still means "what is rendered right now". It is
just no longer the default.

---

## Multi-page forms

This is the one case that needs attention.

If only the current step's `Form` is mounted, `activeFields` used to scope
results to that step **by accident of widget lifecycle**. It no longer does:

```dart
// On step 3 of 3.
FormResults.getResults(controller: controller);
// before: step 3's fields
// after:  every step registered so far — and it validates them
```

Scope it explicitly. Both work; the first is shorter:

```dart
FormResults.getResults(controller: controller, pageName: 'step-3');
FormResults.getResults(controller: controller, fields: controller.getPageFields('step-3'));
```

For a per-step validity check, `validatePage` and `isPageValid` already exist
and are unaffected.

To keep the old behavior verbatim while you decide:

```dart
FormResults.getResults(controller: controller, fields: controller.activeFields);
```

Note the exposure is bounded: a step that has never been mounted has never been
registered. The exception is the prepopulate pattern —
`controller.addFields([...page1, ...page2, ...page3])` — which registers
everything up front, so the unscoped call sees all of it. Use `pageName:`.

### Final submit

The unscoped call is now the right one for a final submit: it returns every
answer the person gave, including the steps they have navigated away from.
That is what `docs/guides/pages.md` has always said it did.

---

## `checkForErrors` is honored

The flag was documented but never read, so every call ran every validator and
wrote through to `controller.clearErrors` / `controller.addError`.

If you passed `checkForErrors: false` you believed you had a side-effect-free
read. Now you do. Nothing to change — but if you were unknowingly *relying* on
the validation that ran anyway, add an explicit `getResults(controller: c)` or
`controller.validateForm()`.

Related: `getResultsReadOnly` reports errors scoped to the fields it collected,
rather than the controller's whole-form list. A read scoped to one field no
longer reports `errorState: true` because a different field is invalid.

---

## Hidden and disabled fields are unchanged

Worth restating, since the scope change makes it load-bearing:

| | in `results` | validated |
|---|---|---|
| `hideField: true`, or an unsatisfied `conditional` | no | no |
| `disabled: true` | **yes** | no |
| everything else | yes | yes |

`hideField`/`conditional` are the mechanism for "not part of this submission" —
the field stays registered and keeps its value, so unhiding restores the
answer. `disabled` means shown-but-locked: a server-populated email or a record
id is still part of the answer and must round-trip. This is deliberately *not*
HTML's `disabled`.

`validateForm()` now honors both rules too, so controller-driven and
`FormResults`-driven validation no longer disagree about which fields count.

---

## Dynamic `fields:` lists

A field **added** to a live `fields:` list is now registered. Previously
registration only ever happened in the initial post-frame callback, so the
field was invisible to the controller and `updateFieldValue` on it threw
`ArgumentError`.

A field **removed** from the list is deliberately *not* withdrawn. A wizard
swaps one `Form`'s list per step and Flutter reuses the State, so "no longer
listed" cannot be told apart from "you are on a later page" — withdrawing would
delete steps the person already filled in.

When a field is genuinely gone, say so:

```dart
controller.unregisterFields(['optional-note']);           // keeps the value
controller.unregisterFields(['optional-note'], keepValues: false);
controller.removeField('optional-note');                  // also disposes controllers
```

Better still, express it with `conditional` or `hideField`, which keep the
field declared while excluding it from results and validation — and let the
answer come back if it reappears.

---

## `FormController.fields` is deprecated

It was assigned once in the constructor and never read or written anywhere in
the package, so `FormController(fields: [...])` registered nothing.

```dart
controller.fields          // deprecated, now delegates
controller.registeredFields // use this
```

The constructor parameter now actually registers its fields, which is what
everyone assumed it did.

---

## New API summary

| | |
|---|---|
| `FormController.registeredFields` | the form's schema, declaration order |
| `FormController.registeredFieldIds` | lazy id-only companion |
| `FormController.unregisterFields` | withdraw fields, keeping values by default |
| `FormController.getFieldValueOrNull` | read a possibly-undeclared field without throwing |
| `FormResults.getResults(pageName:)` | page scoping without `getPageFields` |
| `FormResults.grabOrNull` | tells absent apart from empty |
