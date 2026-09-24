RSpec.describe "Shaded Netty dependencies" do
  it "preserves the package suffix required by Netty's native library loader" do
    jar = java.util.jar.JarFile.new(File.expand_path("../lib/ext/rabbitmq-client-netty-shaded.jar", __dir__))
    begin
      loader_entry = jar.entries.to_a.map(&:name).find do |name|
        name.end_with?("/netty/util/internal/NativeLibraryLoader.class")
      end
    ensure
      jar.close
    end

    expect(loader_entry).not_to be_nil
    loader = JavaUtilities.get_proxy_class(loader_entry.delete_suffix(".class").tr("/", "."))
    # Exercise the prefix check without requiring a platform-specific native library
    prefix_method = loader.java_class.declared_method("calculateMangledPackagePrefix")
    prefix_method.accessible = true
    expect(prefix_method.invoke_static).to eq("com_rabbitmq_marchhare_shaded_")
  end
end
