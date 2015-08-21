module Fauna
  module Model
    def self.get_path(path, data)
      path.inject(data) do |obj, element|
        break unless obj.is_a? Hash
        obj[element]
      end
    end

    def self.set_path(path, value, data)
      path = path.clone
      last_key = path.pop
      data = path.inject(data) do |obj, element|
        obj[element] = {} unless obj[element].is_a? Hash
        obj[element]
      end
      data[last_key] = value
    end

    def self.delete_path(path, data)
      path = path.clone
      last_key = path.pop
      data = path.inject(data) do |obj, element|
        break unless obj[element].is_a? Hash
        obj[element]
        continue
      end
      data.delete(last_key) if data.is_a? Hash
    end

    def self.hash_dup(obj)
      if obj.is_a? Hash
        obj.each_with_object({}) do |(key, value), object|
          object[key] = hash_dup(value)
        end
      else
        obj
      end
    end

    def self.calculate_diff(source, updated)
      (source.keys | updated.keys).each_with_object({}) do |key, diff|
        if source.key? key
          if updated.key? key
            old = source[key]
            new = updated[key]
            if old.is_a?(Hash) && new.is_a?(Hash)
              inner_diff = calculate_diff(old, new)
              diff[key] = inner_diff unless inner_diff.empty?
            elsif old != new
              diff[key] = new
            end
          else
            diff[key] = nil
          end
        else
          diff[key] = updated[key]
        end
      end
    end

    def self.calculate_diff?(source, updated)
      if source.is_a?(Hash) && updated.is_a?(Hash)
        (source.keys | updated.keys).each do |key|
          if source.key? key
            if updated.key? key
              old = source[key]
              new = updated[key]
              if old.is_a?(Hash) && new.is_a?(Hash)
                return true if calculate_diff?(old, new)
              elsif old != new
                return true
              end
            else
              return true
            end
          else
            return true
          end
        end
      elsif source != updated
        return true
      end

      false
    end
  end
end
