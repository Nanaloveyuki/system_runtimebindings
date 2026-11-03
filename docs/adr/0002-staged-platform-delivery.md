# Staged Platform Delivery

Status: accepted

Deliver Android first, and begin HarmonyOS API evaluation only after the Android MVP's capability contract, adapter, and verification path are stable. The project remains one cross-platform capability layer, not two independent submissions; staging avoids making MoonOHOS APIs, HarmonyOS device access, and any shim prerequisites for the first usable Android release. Future HarmonyOS scope is conditional on published upstream interfaces and a concrete matching capability. Cross-platform modules and conformance abstractions are introduced only when multiple real adapters establish shared semantics, rather than being required in the Android MVP.