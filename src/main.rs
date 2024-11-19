use clap::Parser;
use git2::Repository;

#[derive(Parser, Debug)]
struct Args {
	pick_from: String,
}

fn main() {
	let args = Args::parse();
	let repo = match Repository::open(match std::env::current_dir() {
		Ok(pathbuf) => pathbuf,
		Err(e) => panic!("failed to get cwd: {}", e),
	}) {
		Ok(repo) => repo,
		Err(e) => panic!("failed to open: {}", e),
	};
	repo.merge(
		&[&repo
			.find_annotated_commit(repo.revparse_ext(&args.pick_from).unwrap().0.id())
			.unwrap()],
		None,
		None,
	)
	.unwrap();
	repo.cleanup_state().unwrap();
}
