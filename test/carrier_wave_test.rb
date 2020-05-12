require_relative "test_helper"

class CarrierWaveTest < Minitest::Test
  def teardown
    @content = nil
  end

  def test_encrypt
    uploader = TextUploader.new
    uploader.store!(uploaded_file)

    assert_equal "#{content}!!", uploader.read
    refute_equal uploader.file.read, uploader.read

    assert_equal "#{content}!!..", uploader.thumb.read
    refute_equal uploader.thumb.file.read, uploader.read
  end

  def test_no_encrypt
    uploader = ImageUploader.new
    uploader.store!(uploaded_file)

    assert_equal content, uploader.read
    assert_equal uploader.file.read, uploader.read
  end

  def test_rotate_encryption
    file = uploaded_file

    uploader = TextUploader.new
    uploader.store!(file)

    ciphertext = uploader.file.read
    thumb_ciphertext = uploader.thumb.file.read

    uploader = TextUploader.new
    uploader.retrieve_from_store!(File.basename(file.path))

    uploader.rotate_encryption!

    refute_equal ciphertext, uploader.file.read
    assert_equal "#{content}!!", uploader.read

    refute_equal thumb_ciphertext, uploader.thumb.file.read
    assert_equal "#{content}!!..", uploader.thumb.read

    assert uploader.enable_processing
  end

  def test_image
    path = "test/support/image.png"
    uploader = AvatarUploader.new
    uploader.store!(File.open(path))

    assert_equal "image/png", uploader.content_type
    assert_equal File.binread(path), uploader.read

    uploader = AvatarUploader.new
    uploader.retrieve_from_store!("image.png")

    assert_equal "image/png", uploader.content_type
    assert_equal File.binread(path), uploader.read
  end

  def test_mounted
    skip if mongoid?

    path = "test/support/image.png"
    message = File.binread(path)
    file = File.open(path)

    user = User.create!(document: file)

    assert_equal message, user.document.read
    refute_equal message, user.document.file.read

    user = User.last
    assert_equal message, user.document.read
    assert_equal "image/png", user.document.content_type
    refute_equal message, user.document.file.read
  end

  def test_mounted_many
    skip if mongoid?

    path = "test/support/image.png"
    message = File.binread(path)
    file = File.open(path)

    user = User.create!(documents: [file])

    assert_equal message, user.documents.first.read
    refute_equal message, user.documents.first.file.read

    user = User.last
    assert_equal message, user.documents.first.read
    assert_equal "image/png", user.documents.first.content_type
    refute_equal message, user.documents.first.file.read
  end

  def content
    @content ||= "Test #{rand(1000)}"
  end

  def uploaded_file
    file = Tempfile.new
    file.write(content)
    file.rewind
    file
  end
end
