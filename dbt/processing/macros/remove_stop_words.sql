{% macro remove_stop_words(column_name) %}
    
    TRIM(REGEXP_REPLACE(
        LOWER({{ column_name }}),
        r'\b(a|an|the|and|or|but|is|are|was|were|be|been|being|have|has|had|do|does|did|to|at|in|on|by|for|with|about|against|between|into|through|during|before|after|above|below|from|up|down|of|off|over|under|again|further|then|once|here|there|when|where|why|how|all|any|both|each|few|more|most|other|some|such|no|nor|not|only|own|same|so|than|too|very|can|will|just|should|now|au|aux|avec|ce|ces|dans|de|des|du|elle|en|et|eux|il|ils|je|la|le|les|leur|lui|ma|mais|me|même|mes|moi|mon|nos|notre|nous|on|ou|par|pas|pour|qu|que|qui|sa|se|si|son|sur|ta|te|tes|toi|ton|tu|un|une|votre|vous|c|d|j|l|à|m|n|s|t|y|été|étée|étées|étés|étant|étante|étants|étantes|suis|es|est|sommes|êtes|sont|serai|seras|sera|serons|serez|seront|serais|serait|serions|seriez|seraient|étais|était|étions|étiez|étaient|fus|fut|fûmes|fûtes|furent|sois|soit|soyons|soyez|soient|fusse|fusses|fût|fussions|fussiez|fussent|ceci|cela|cet|cette|ici|ils|les|leurs|quel|quels|quelle|quelles|sans|soi|alors|comme|donc|dont|lors|chez)\b',
        ' '
    ))
    
{% endmacro %}