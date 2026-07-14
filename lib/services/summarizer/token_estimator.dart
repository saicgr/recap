/// Cheap, dependency-free token estimate.
///
/// 3.6 chars/token is DELIBERATELY conservative (it over-estimates on ordinary
/// prose, where ~4.0 is the usual rule of thumb). ASR output is not ordinary
/// prose: it is dense with digit strings spoken one at a time ("6 5 7 6 6"),
/// promo IDs, and mangled words that no BPE merge covers — all of which
/// tokenize far worse than clean English. Under-estimating here silently
/// overflows the on-device context window, which is exactly the bug this
/// pipeline exists to fix. Over-estimating only costs us one extra chunk.
///
/// Never swap this for a real tokenizer without also raising the reserve in the
/// pipeline: the pipeline's safety margin assumes this number is pessimistic.
int estimateTokens(String s) => (s.length / 3.6).ceil();
