#!ruby -w

module A
	def xyz()
		'A::xyz';
	end
end

module B
	def xyz()
		'B::xyz';
	end
end


include A, B;

puts 'xyz: ' + xyz(); # => A::xyz

