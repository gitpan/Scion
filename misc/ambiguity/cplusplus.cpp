/*
	$ g++ -o cplusplus cplusplus.cpp

	error: request for member `xyz' is ambiguous
	error: candidates are: std::string B::xyz()
	error:                 std::string A::xyz()
	$
*/

#include <iostream>
#include <string>


class A{
	std::string xyz_;

	public:

	A(std::string s = "A::xyz") : xyz_(s){
	}

	std::string xyz(){
		return xyz_;
	}
};

class B{
	std::string xyz_;

	public:

	B(std::string s = "B::xyz") : xyz_(s){
	}
	std::string xyz(){
		return xyz_;
	}
};

class C : public A, B{
};


int main(){
	C x;

	std::cout << "xyz: " << x.xyz() << std::endl;
	return 0;
}
