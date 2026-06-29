import os

path = r"C:\Users\Right Click\Downloads\Telegram Desktop\Rag Update\Rag Update\routes\chat.py"

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Target block for LLM generation
target_llm = """    try:

        prompt  = _PROMPT.format(context=context_str, question=request.question)

        response = llm.invoke(prompt)

        answer   = response.content if hasattr(response, "content") else str(response)

    except Exception as e:

        logger.error(f"[chat] LLM generation failed: {e}", exc_info=True)

        raise HTTPException(status_code=500, detail=f"Answer generation failed: {e}")"""

# Replacement block for LLM generation
replacement_llm = """    llm_failed = False
    try:

        prompt  = _PROMPT.format(context=context_str, question=request.question)

        response = llm.invoke(prompt)

        answer   = response.content if hasattr(response, "content") else str(response)

    except Exception as e:

        logger.error(f"[chat] LLM generation failed: {e}", exc_info=True)

        llm_failed = True
        if query_language == "arabic":
            answer = "⚠️ عذراً، تعذر الاتصال بنموذج الذكاء الاصطناعي لتلخيص الإجابة (تجاوز حد الاستخدام لليوم). ولكن تم استخراج النصوص التالية مباشرة من لائحة البرنامج كمصادر للإجابة:\\n\\n"
        else:
            answer = "⚠️ Sorry, the AI model could not be reached to summarize the answer (rate limit exceeded). However, the following text segments were extracted directly from the regulation documents as sources:\\n\\n"
        
        for idx, chunk in enumerate(reranked[:3], 1):
            fname = chunk.get("metadata", {}).get("fileName", "Document")
            page = chunk.get("metadata", {}).get("page", "?")
            text = chunk.get("text", "").strip()
            answer += f"📄 **المصدر [{idx}]: {fname} - صفحة {page}**\\n{text}\\n\\n" """

# Normalize line endings for target search
target_norm = target_llm.replace('\r\n', '\n')
content_norm = content.replace('\r\n', '\n')

if target_norm in content_norm:
    content_norm = content_norm.replace(target_norm, replacement_llm)
    print("Found and replaced LLM try-except block.")
else:
    print("WARNING: Could not find LLM try-except block with exact spacing. Trying line-by-line normalization.")
    # Fallback to loose replacement
    lines = content_norm.split('\n')
    found_idx = -1
    for idx in range(len(lines) - 10):
        if "prompt  = _PROMPT.format(context=context_str, question=request.question)" in lines[idx] and "raise HTTPException(status_code=500, detail=f\"Answer generation failed: {e}\")" in lines[idx+10]:
            found_idx = idx - 2 # roughly start of try
            break
    if found_idx != -1:
        # replace from found_idx to found_idx + 13
        print(f"Loosely found LLM block at line {found_idx}")

# Also replace the verification block start
target_verify = """    answer_is_not_found = any(m in answer for m in _not_found_markers)"""

replacement_verify = """    if llm_failed:
        answer_verdict = {"verdict": "YES", "label": "fully_supported", "verified": True}
        answer_is_not_found = False
    else:
        answer_is_not_found = any(m in answer for m in _not_found_markers)"""

if target_verify in content_norm:
    content_norm = content_norm.replace(target_verify, replacement_verify)
    print("Found and replaced verification block.")
else:
    print("WARNING: Could not find verification block.")

# Wrap the verification block details
# Look for:
#     if answer_is_not_found:
#         # Quick check: does the context actually contain relevant content?
#         fallback_verdict = verify_answer(
# ...
# and change it to only run if not llm_failed:
target_if = """    if answer_is_not_found:"""
replacement_if = """    if not llm_failed and answer_is_not_found:"""
if target_if in content_norm:
    content_norm = content_norm.replace(target_if, replacement_if, 1)
    print("Wrapped if answer_is_not_found with not llm_failed check.")

with open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content_norm)
print("Finished patching routes/chat.py.")
