require 'jekyll'

module Jekyll
  module TagRawFilter
    def auto_wrap_tags(content)
      # 이미 {% raw %} 태그로 감싸져있는 부분은 건너뛰도록 처리
      # raw 태그로 감싸져 있지 않은 Django/Liquid 태그를 찾아서 raw로 감싸기
      
      # 정규식을 사용하여 {% raw %}...{% endraw %} 블록 찾기
      raw_blocks = content.scan(/\{%\s*raw\s*%\}.*?\{%\s*endraw\s*%\}/m)
      
      # raw 블록의 내용을 임시 토큰으로 대체
      raw_block_tokens = {}
      raw_blocks.each_with_index do |block, i|
        token = "RAW_BLOCK_TOKEN_#{i}"
        raw_block_tokens[token] = block
        content = content.sub(block, token)
      end
      
      # 자동으로 raw 태그로 감싸야 할 태그 패턴들
      patterns = [
        /\{%\s*csrf_token\s*%\}/,
        /\{%\s*url\s+[^%]*%\}/,
        /\{%\s*extends\s+[^%]*%\}/,
        /\{%\s*block\s+[^%]*%\}.*?\{%\s*endblock\s*[^%]*%\}/m,
        /\{%\s*for\s+[^%]*%\}.*?\{%\s*endfor\s*%\}/m,
        /\{%\s*if\s+[^%]*%\}.*?\{%\s*endif\s*%\}/m
      ]
      
      patterns.each do |pattern|
        content.gsub!(pattern) do |match|
          "{% raw %}#{match}{% endraw %}"
        end
      end
      
      # 임시 토큰을 원래 raw 블록으로 복원
      raw_block_tokens.each do |token, block|
        content = content.sub(token, block)
      end
      
      content
    end
  end
end

Liquid::Template.register_filter(Jekyll::TagRawFilter)

Jekyll::Hooks.register [:posts, :pages], :pre_render do |document|
  if document.extname == '.md' || document.extname == '.html'
    document.content = document.content.to_s.auto_wrap_tags
  end
end 