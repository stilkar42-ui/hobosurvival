# Hobo Survival – Fading Meter System Specification v1

## Feature Name

Fading Meter / Identity Erosion System

---

## Purpose

The Fading Meter represents the protagonist’s gradual loss of identity, dignity, and psychological stability as life on the road erodes the values and purpose that originally drove him.

This system exists to:

* Add psychological and thematic pressure beyond raw survival stats
* Reinforce the core fantasy of “survival with purpose”
* Prevent the gameplay loop from collapsing into pure optimization/resource management
* Create long-term consequences for sustained desperate or degrading behavior

---

## Design Philosophy

The Fading Meter is NOT a punishment for isolated bad choices.

It tracks **behavioral drift over time**, not single actions.

A man does not lose himself in one bad day.
He fades through repeated compromise.

---

## Core Rules

### Meter Range

* Integer value from 0 to 100

### Visibility

* Hidden by default
* Semi-visible through narrative/UI cues
* Exact value optionally shown in debug / advanced passport view

---

## Evaluation Model

### Update Timing

Evaluate once per sleep/day cycle.

### Calculation Method

Use rolling behavioral analysis over recent days instead of flat per-action penalties.

Recommended window:

* Last 3 days (prototype)
* Expandable to 5+ later

---

## Fade Gain Factors

### Economic / Moral Drift

* High percentage of income from theft / crime / exploitative shortcuts
* High percentage of food from scavenging/charity vs earned purchase
* Excessive dependence on alcohol/tobacco comfort items

### Social Isolation

* No positive camp/social interactions for multiple days
* Repeated refusal to help allies/camp members

### Survival Degradation

* Poor sleep quality
* Sleeping in unsafe/exposed conditions repeatedly
* Chronic low morale

### Family Neglect

* Extended time without sending meaningful money home
* Ignoring urgent family requests/events

---

## Fade Reduction Factors

### Honest Labor

* Completing legitimate work shifts
* Bonus for difficult or dignified labor

### Providing For Family

* Sending money home
* Bonus for meaningful remittance thresholds

### Brotherhood / Community

* Helping other hobos
* Sharing food/supplies
* Positive campfire/social events

### Self Maintenance

* Good hygiene
* Maintaining gear/clothing
* Sleeping in proper shelter

### Restorative Dreams

* Positive dream events tied to family/home/hope

---

## Decay / Recovery Principle

Recovery is slower than loss.

Recommended Prototype Tuning:

* Fade Gain Multiplier: 1.0
* Fade Recovery Multiplier: 0.5

Meaning:
Loss occurs roughly twice as fast as recovery.

---

## Threshold States

### 0–24: Steady

* No effects
* Positive/neutral dream pool

---

### 25–49: Fraying

Effects:

* Occasional hollow dream text
* Minor morale recovery reduction
* Slightly darker internal monologue flavor

---

### 50–74: Slipping

Effects:

* Morale harder to restore
* Passport may gain negative remarks/raps
* Job text/descriptions become more cynical
* Family letters grow worried/distant

---

### 75–99: Lost

Effects:

* Significant morale penalties
* Severe dream distortion/nightmares
* Dialogue options skew bitter/defeatist
* NPC perception worsens

---

### 100: Collapse State (Optional Future Feature)

Potential systems:

* Breakdown event
* Forced return home
* Permanent trait scar
* Soft fail / ending trigger in Broken Road mode

---

## System Interactions

### Morale

* Low Morale increases Fade growth
* High Fade reduces Morale recovery

### Dream System

* Fade influences dream pool weighting
* Higher Fade increases nightmare frequency

### Family Letter System

* Letter tone shifts based on Fade thresholds

### Passport / Reputation

* High Fade can add negative descriptors / status drift

---

## UI / Feedback

Never rely solely on raw numbers.

Use atmospheric feedback:

* Dream text changes
* Internal monologue changes
* Family letter tone shifts
* Subtle UI degradation / roughness (future)
* Passport flavor descriptors

---

## Implementation Notes

### Required Data Tracking

Track rolling recent history:

* Income source breakdown
* Food source breakdown
* Social interaction score
* Sleep quality history
* Money sent home history
* Comfort item usage

---

## Prototype Goal

Implement the system in lightweight form without disrupting existing gameplay loop.

Initial prototype only needs:

* Integer fade value
* Daily evaluation function
* Threshold effect hooks
* Debug display

Advanced narrative integration can be layered later.

---

## Acceptance Criteria

Feature is complete when:

* Fade updates once per day
* Fade responds to tracked behaviors
* Threshold effects trigger correctly
* Debug UI displays current value/state
* System can be tuned via exposed variables
