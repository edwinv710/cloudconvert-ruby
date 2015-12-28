class Hash
   def deep_symbolize
      self.inject({}) do |new_hash, (key,value)| 
            new_hash[key.to_sym] = value.deep_symbolize
            new_hash
      end
   end
end

class Array
   def deep_symbolize
      map(&:deep_symbolize)
   end
end

class Object
   def deep_symbolize
      return self
   end
end