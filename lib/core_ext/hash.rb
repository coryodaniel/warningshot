class Hash
  def symbolize_keys!
    each do |k,v|
      sym = k.respond_to?(:to_sym) ? k.to_sym : k
      self[sym] = Hash === v ? v.symbolize_keys! : v
      self[sym] = Array === v ? v.each{|i|
        i.symbolize_keys! if i.is_a? Hash
      }: v

      delete(k) unless k == sym
    end
    self
  end
end