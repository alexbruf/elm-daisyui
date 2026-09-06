-- Tries: give a page six sections by passing a 6th argument to `Sections5`,
-- the largest arity `Sections` has.
-- Proves: the page content budget of at most five sections is a type-level
-- fact. There is no `Sections6` constructor, and `Sections5` itself is fixed
-- at five arguments, so "six sections" cannot be constructed at all.


module Reject.SixSections exposing (value)

import Daisy.Tree as Tree exposing (..)


oneSection : Section msg
oneSection =
    Stack defaultStackConfig []


value : Sections msg
value =
    Sections5 oneSection oneSection oneSection oneSection oneSection oneSection
