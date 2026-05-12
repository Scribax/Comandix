import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {}

  findAll(restaurantId: string) {
    return this.repo.find({ where: { restaurantId } });
  }

  async create(restaurantId: string, data: Partial<User> & { password: string }) {
    const passwordHash = await bcrypt.hash(data.password, 10);
    return this.repo.save(this.repo.create({ ...data, restaurantId, passwordHash }));
  }

  update(id: string, data: Partial<User>) {
    return this.repo.update(id, data);
  }

  remove(id: string) {
    return this.repo.delete(id);
  }
}
