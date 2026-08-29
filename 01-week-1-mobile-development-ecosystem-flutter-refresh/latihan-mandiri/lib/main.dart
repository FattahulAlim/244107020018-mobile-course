double hitungLuasPersegiPanjang(double panjang, double lebar){
  double luas = panjang * lebar;

  return luas;
}

class Profil {

  Profil(this.nama, this.nim, this.email);

  String nama;
  String nim;
  String? email;

  void cetakInfo(){
    print("Nama: $nama");
    print("nim: $nim");
    print("Email: ${email ?? 'Email belum terdaftar'}");
  }
}

void main(){
  double luas = hitungLuasPersegiPanjang(6.0, 2.0);
  print("Luas persegi panjang = $luas");
  print('');

  var mahasiswa = Profil("Fattahul", "244107020018", null);
  print(mahasiswa.nama);
  print(mahasiswa.nim);
  print(mahasiswa.email ?? "Email belum terdaftar");
  print('');
  
  mahasiswa.cetakInfo();
}

