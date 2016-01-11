class Hash
   def except(key)
      hash = self.dup
      hash.remove(key)
      return hash
   end
end